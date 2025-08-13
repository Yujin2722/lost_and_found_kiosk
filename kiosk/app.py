from flask import Flask, render_template, request, redirect, url_for, session
from flask import jsonify
import sqlite3
import hashlib
import requests
import time

app = Flask(__name__)
app.secret_key = "supersecretkey"

WEMOS_IP = "http://192.168.137.132"  # Adjust to your Wemos IP

# Centralized LED category list
CATEGORIES = ["phone", "wallet", "umbrella", "calculator", "random"]

def init_db():
    conn = sqlite3.connect("lost_found.db")
    c = conn.cursor()
    c.execute("""CREATE TABLE IF NOT EXISTS students (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    tcc_number TEXT UNIQUE,
                    name TEXT)""")
    c.execute("""CREATE TABLE IF NOT EXISTS admin_users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT UNIQUE,
                    password_hash TEXT)""")
    c.execute("""CREATE TABLE IF NOT EXISTS csu_users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT UNIQUE,
                    password_hash TEXT)""")
    c.execute("""CREATE TABLE IF NOT EXISTS reports (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    tcc_number TEXT,
                    report_type TEXT,
                    category TEXT,
                    description TEXT,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)""")
    conn.commit()
    conn.close()

def hash_password(pw):
    return hashlib.sha256(pw.encode()).hexdigest()

def verify_user(table, username, password):
    conn = sqlite3.connect("lost_found.db")
    c = conn.cursor()
    c.execute(f"SELECT password_hash FROM {table} WHERE username=?", (username,))
    row = c.fetchone()
    conn.close()
    return row and row[0] == hash_password(password)

def is_registered(tcc):
    conn = sqlite3.connect("lost_found.db")
    c = conn.cursor()
    c.execute("SELECT * FROM students WHERE tcc_number=?", (tcc,))
    r = c.fetchone()
    conn.close()
    return r is not None

@app.route("/")
def home():
    return redirect(url_for("submit_report"))

# PUBLIC: Submit lost/found report
@app.route("/submit_report", methods=["GET", "POST"])
def submit_report():
    if request.method == "POST":
        tcc = request.form.get("tcc_number")
        rtype = request.form.get("report_type")
        category = request.form.get("category")
        desc = request.form.get("description")
        if not is_registered(tcc):
            return "TCC not registered.", 403

        conn = sqlite3.connect("lost_found.db")
        c = conn.cursor()
        c.execute("INSERT INTO reports (tcc_number, report_type, category, description) VALUES (?, ?, ?, ?)",
                  (tcc, rtype, category, desc))
        conn.commit()
        conn.close()

        if rtype == "lost":
            return "Lost report submitted."
        elif rtype == "found":
            try:
                requests.get(f"{WEMOS_IP}/led/on/{category}", timeout=3)
                time.sleep(5)
                requests.get(f"{WEMOS_IP}/led/off/{category}", timeout=3)
            except Exception as e:
                return f"Failed to control LED: {e}", 500
            return "Found report submitted and LED toggled."
        else:
            return "Invalid report type.", 400

    return render_template("submit_report.html", categories=CATEGORIES)

# ADMIN LOGIN
@app.route("/admin/login", methods=["GET", "POST"])
def admin_login():
    if request.method == "POST":
        u = request.form.get("username")
        p = request.form.get("password")
        if verify_user("admin_users", u, p):
            session["admin_user"] = u
            return redirect(url_for("admin_dashboard"))
        else:
            return render_template("admin_login.html", error="Invalid credentials")
    return render_template("admin_login.html")

@app.route("/admin/logout")
def admin_logout():
    session.pop("admin_user", None)
    return redirect(url_for("admin_login"))

# ADMIN DASHBOARD
@app.route("/admin/dashboard")
def admin_dashboard():
    if "admin_user" not in session:
        return redirect(url_for("admin_login"))
    conn = sqlite3.connect("lost_found.db")
    c = conn.cursor()
    c.execute("SELECT * FROM students ORDER BY id DESC")
    students = c.fetchall()
    c.execute("""
        SELECT reports.id, reports.tcc_number, students.name, reports.report_type,
               reports.category, reports.description, reports.timestamp
        FROM reports LEFT JOIN students ON reports.tcc_number = students.tcc_number
        ORDER BY reports.timestamp DESC
    """)
    reports = c.fetchall()
    conn.close()
    return render_template("admin_dashboard.html", students=students, reports=reports)

# ADMIN REGISTER STUDENT
@app.route("/admin/register_student", methods=["POST"])
def admin_register_student():
    if "admin_user" not in session:
        return redirect(url_for("admin_login"))
    tcc = request.form.get("tcc_number")
    name = request.form.get("name")
    conn = sqlite3.connect("lost_found.db")
    c = conn.cursor()
    try:
        c.execute("INSERT INTO students (tcc_number, name) VALUES (?, ?)", (tcc, name))
        conn.commit()
    except:
        pass
    conn.close()
    return redirect(url_for("admin_dashboard"))

# DELETE REPORT
@app.route("/admin/delete_report/<int:report_id>", methods=["POST"])
def delete_report(report_id):
    if "admin_user" not in session:
        return redirect(url_for("admin_login"))
    conn = sqlite3.connect("lost_found.db")
    c = conn.cursor()
    c.execute("DELETE FROM reports WHERE id=?", (report_id,))
    conn.commit()
    conn.close()
    return redirect(url_for("admin_dashboard"))

# CSU LOGIN
@app.route("/csu/login", methods=["GET", "POST"])
def csu_login():
    if request.method == "POST":
        u = request.form.get("username")
        p = request.form.get("password")
        if verify_user("csu_users", u, p):
            session["csu_user"] = u
            return redirect(url_for("csu_control"))
        else:
            return render_template("csu_login.html", error="Invalid credentials")
    return render_template("csu_login.html")

@app.route("/csu/logout")
def csu_logout():
    session.pop("csu_user", None)
    return redirect(url_for("csu_login"))

# CSU LED control (no history)
@app.route("/csu/control_led", methods=["GET", "POST"])
def csu_control():
    if "csu_user" not in session:
        return redirect(url_for("csu_login"))

    msg = ""
    if request.method == "POST":
        action = request.form.get("action")  # on or off
        category = request.form.get("category")
        if action not in ("on", "off") or not category:
            msg = "Invalid action or category"
        else:
            try:
                requests.get(f"{WEMOS_IP}/led/{action}/{category}", timeout=3)
                msg = f"LED {action}ed for {category}"
            except Exception as e:
                msg = f"Failed to control LED: {e}"

    return render_template("csu_control.html", message=msg, categories=CATEGORIES)
# found items to app
@app.route("/found-items", methods=["GET"])
def get_found_items():
    conn = sqlite3.connect("lost_found.db")
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    c.execute("""
        SELECT id, tcc_number, category, description
        FROM reports
        WHERE report_type = 'found'
    """)
    rows = c.fetchall()
    conn.close()
    return jsonify([dict(row) for row in rows])

# lost items to app
@app.route("/lost-items", methods=["GET"])
def get_lost_items():
    conn = sqlite3.connect("lost_found.db")
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    c.execute("""
        SELECT id, tcc_number, category, description
        FROM reports
        WHERE report_type = 'lost'
    """)
    rows = c.fetchall()
    conn.close()
    return jsonify([dict(row) for row in rows])


if __name__ == "__main__":
    init_db()

    # Create default admin and csu users if none
    conn = sqlite3.connect("lost_found.db")
    c = conn.cursor()
    c.execute("SELECT COUNT(*) FROM admin_users")
    if c.fetchone()[0] == 0:
        c.execute("INSERT INTO admin_users (username, password_hash) VALUES (?, ?)",
                  ("admin", hash_password("admin123")))
    c.execute("SELECT COUNT(*) FROM csu_users")
    if c.fetchone()[0] == 0:
        c.execute("INSERT INTO csu_users (username, password_hash) VALUES (?, ?)",
                  ("csu", hash_password("csu123")))
    conn.commit()
    conn.close()

    app.run(host="0.0.0.0", port=5001, debug=True)
