const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const db = require('../db');

const router = express.Router();

// Make sure upload path exists
const uploadPath = path.join(__dirname, '..', 'uploads', 'faces');
fs.mkdirSync(uploadPath, { recursive: true });

const storage = multer.diskStorage({
  destination: (_, __, cb) => cb(null, uploadPath),
  filename: (req, file, cb) => {
    const { employeeId } = req.params;
    cb(null, `${employeeId}.jpg`);
  },
});

const upload = multer({ storage });

// ───── POST /upload-face/:employeeId ─────
router.post('/upload-face/:employeeId', upload.single('face'), async (req, res) => {
  const { employeeId } = req.params;
  const imageUrl = `http://localhost:3000/uploads/faces/${employeeId}.jpg`;

  try {
    const [result] = await db.query(
      'UPDATE employees SET face_image_url = ? WHERE employee_id = ?',
      [imageUrl, employeeId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    res.json({ success: true, url: imageUrl });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

module.exports = router;
