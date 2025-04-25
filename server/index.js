const express = require('express');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
const port = 3000;
const secretKey = 'your_secret_key'; // استخدم مفتاحًا قويًا

// Middleware
app.use(bodyParser.json());
app.use(cors()); // تمكين CORS للاتصال مع تطبيق Flutter

// إنشاء اتصال بقاعدة البيانات
const db = new sqlite3.Database('./database.db');

// إنشاء جدول المستخدمين
db.serialize(() => {
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      phone TEXT NOT NULL,
      phone_code TEXT NOT NULL
    )
  `);
});

// تسجيل مستخدم جديد مع تشفير كلمة المرور
app.post('/register', async (req, res) => {
  const { name, email, password, phone, phone_code } = req.body;

  if (!name || !email || !password || !phone || !phone_code) {
    return res.status(400).json({ message: 'All fields are required' });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const query = `INSERT INTO users (name, email, password, phone, phone_code) VALUES (?, ?, ?, ?, ?)`;

    db.run(query, [name, email, hashedPassword, phone, phone_code], function (err) {
      if (err) {
        return res.status(500).json({ message: 'Error registering user', error: err.message });
      }
      res.status(201).json({ message: 'User registered successfully', userId: this.lastID });
    });
  } catch (error) {
    res.status(500).json({ message: 'Error encrypting password', error: error.message });
  }
});

// تسجيل الدخول مع JWT
app.post('/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  const query = `SELECT * FROM users WHERE email = ?`;
  db.get(query, [email], async (err, user) => {
    if (err) {
      return res.status(500).json({ message: 'Error logging in', error: err.message });
    }
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const token = jwt.sign({ id: user.id, email: user.email }, secretKey, { expiresIn: '24h' });

    res.status(200).json({
      message: 'Login successful',
      user: { id: user.id, name: user.name, email: user.email },
      token,
    });
  });
});

// بدء الخادم
app.listen(port, () => {
  console.log(`✅ Server is running on http://localhost:${port}`);
});
