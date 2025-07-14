require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const path    = require('path');

const authRoutes       = require('./routes/auth');
const employeeRoutes   = require('./routes/employees');
const attendanceRoutes = require('./routes/attendance');
const uploadRoutes     = require('./routes/upload');

const app = express();
app.use(cors());
app.use(express.json());

const uploadDir = process.env.UPLOAD_DIR || 'uploads';
console.log('Using upload directory:', uploadDir);

app.use('/images', express.static(path.join(__dirname, uploadDir)));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.use('/auth',       authRoutes);
app.use('/employees',  employeeRoutes);
app.use('/attendance', attendanceRoutes);
app.use('/', uploadRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`API running on port ${PORT}`));
