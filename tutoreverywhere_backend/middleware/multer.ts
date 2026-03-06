// src/config/multer.ts
import multer from "multer";
import path from "path";
import { fileURLToPath } from 'url';
import { v7 as uuidv7 } from "uuid";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configure storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '../assets/pfp'));
  },
  filename: (req, file, cb) => {
    // const authData = req.body.authData;
    // const userId = authData?.userId || 'unknown';
    const uniqueSuffix = uuidv7().toString();
    const ext = path.extname(file.originalname);
    cb(null, `${uniqueSuffix}-${ext}`);
  }
});

// File filter to only allow images
const fileFilter = (req: any, file: any, cb: any) => {
  const allowedTypes = /jpeg|jpg|png/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb(new Error('Only image files are allowed'));
  }
};

// Create multer upload instance
export const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: fileFilter
});