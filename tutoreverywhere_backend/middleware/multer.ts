import multer from "multer";
import path from "path";

const fileFilter = (req: any, file: any, cb: any) => {
  const extension = path.extname(file.originalname || "").toLowerCase();
  const hasImageMime = (file.mimetype || "").toLowerCase().startsWith("image/");
  const hasKnownImageExtension =
    extension.length === 0 ||
    /\.(jpg|jpeg|png|webp|gif|bmp|heic|heif|tif|tiff|svg)$/i.test(extension);

  if (hasImageMime && hasKnownImageExtension) {
    return cb(null, true);
  }

  cb(new Error("Only image files are allowed"));
};

export const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 15 * 1024 * 1024,
  },
  fileFilter: fileFilter,
});
