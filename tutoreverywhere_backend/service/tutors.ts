import express from "express"
import bodyParser from "body-parser";
import { addTutorSubject, deleteTutorSubject, getTutorSubjects, updateTutorBio, updateTutorPreferredPlace, updateTutorSubjectPrice, viewTutorData, findTutor, updateTutorLocation, updateTutorProfilePicture, updateTutorPromptPayPicture, getPromptPayPictureByTutorId, updateTutorVerificationPhoto } from "../controllers/tutors.ts";
import { verifyToken } from "../middleware/verify.ts";
import formatUserSubjects from "../helpers/formatTutorSubjects.ts";

import { upload } from "../middleware/multer.ts";
import { getAppointmentByTutorId } from "../controllers/appointments.ts";
import { uploadImageToObjectStorage } from "../helpers/objectStorage.ts";

const tutorService = express.Router();

tutorService.use(bodyParser.json());

tutorService.get("/", async (req, res) => {
  const query = req.query;
  const subject = query.subject?.toString();
  const province = query.province?.toString();
  const location = query.location?.toString();
  const maxPrice = query.maxprice?.toString();
  const name = query.name?.toString();
  const sortBy = query.sortby?.toString();
  try {
    const tutors = await findTutor(subject, province, location, maxPrice, name, sortBy);
    const formattedTutors = formatUserSubjects(tutors);
    res.status(200).json(formattedTutors);
  } catch (err) {
    res.status(500).json({message: "Error find tutor" });
  }
})

tutorService.get("/appointments/:userId", async (req, res) => {
  const query = req.query;
  const year = query.year?.toString();
  const month = query.month?.toString();
  const day = query.day?.toString();
  const formattedDateQuery = year + '-' + month + '-' + day;
  const params = req.params;
  const userId = params.userId;
  console.log(formattedDateQuery);
  try {
    const appointments = await getAppointmentByTutorId(userId, formattedDateQuery)
    res.status(200).json(appointments);
  } catch (err) {
    res.status(500).json({message: "Error find tutor" });
  }
})

tutorService.get("/profile/:userId", async (req, res) => {
  const params = req.params;
  const userId = params.userId;
  try {
    const tutorData = await viewTutorData(userId);
    const specific_tutorData = tutorData[0];
    res.status(200).json(specific_tutorData);
  } catch (err) {
    res.status(404).json({message: "Account not found"});
  }
})

tutorService.get("/promptpay-picture/:userId", async (req, res) => {
  const params = req.params;
  const userId = params.userId;
  try {
    const promptPayAsset = await getPromptPayPictureByTutorId(userId)
    const promptPayPicturePath = promptPayAsset[0]?.promptpay_picture?.toString?.() ?? "";
    if (!promptPayPicturePath) {
      return res.status(404).json({ message: "PromptPay picture not found" });
    }

    const promptPayAssetLink = /^https?:\/\//i.test(promptPayPicturePath)
      ? promptPayPicturePath
      : `/${promptPayPicturePath.replace(/^\/+/, "")}`;
    res.redirect(promptPayAssetLink);
  } catch (err) {
    res.status(500).json({message: "Error find tutor" });
  }
})

tutorService.patch(
  "/profile-picture",
  verifyToken,
  (req: any, res: any, next: any) => {
    const authData = req.body.authData;
    upload.single('profilePicture')(req, res, (err) => {
      if (err) return res.status(400).json({ message: err.message });
      req.body.authData = authData;
      next();
    });
  },
  async (req: any, res: any) => {
    const { userId, role } = req.body.authData;

    try {
      if (role !== "tutor") {
        return res.status(403).json({ message: `This user ${userId} is not a tutor` });
      }

      if (!req.file) {
        return res.status(400).json({ message: "No file uploaded" });
      }

      const profilePicturePath = await uploadImageToObjectStorage(req.file, "pfp");
      await updateTutorProfilePicture(userId, profilePicturePath);

      res.status(200).json({
        message: "Successfully updated profile picture",
        profilePicture: profilePicturePath
      });
    } catch (err: any) {
      console.error("Error uploading profile picture", err);
      res
        .status(500)
        .json({ message: err?.message || "Error uploading profile picture" });
    }
  }
);

tutorService.patch(
  "/promptpay-picture",
  verifyToken,
  (req: any, res: any, next: any) => {
    const authData = req.body.authData;
    upload.single('promptPayPicture')(req, res, (err) => {
      if (err) return res.status(400).json({ message: err.message });
      req.body.authData = authData;
      next();
    });
  },
  async (req: any, res: any) => {
    const { userId, role } = req.body.authData;

    try {
      if (role !== "tutor") {
        return res.status(403).json({ message: `This user ${userId} is not a tutor` });
      }

      if (!req.file) {
        return res.status(400).json({ message: "No file uploaded" });
      }

      const promptPayPicturePath = await uploadImageToObjectStorage(req.file, "promptpay");
      await updateTutorPromptPayPicture(userId, promptPayPicturePath);

      res.status(200).json({
        message: "Successfully updated prompt pay picture",
        profilePicture: promptPayPicturePath
      });
    } catch (err: any) {
      console.error("Error uploading prompt pay picture", err);
      res.status(500).json({
        message: err?.message || "Error uploading prompt pay picture",
      });
    }
  }
);

tutorService.patch(
  "/verification-picture",
  verifyToken,
  (req: any, res: any, next: any) => {
    const authData = req.body.authData;
    upload.single('verificationPicture')(req, res, (err) => {
      if (err) return res.status(400).json({ message: err.message });
      req.body.authData = authData;
      next();
    });
  },
  async (req: any, res: any) => {
    const { userId, role } = req.body.authData;

    try {
      if (role !== "tutor") {
        return res.status(403).json({ message: `This user ${userId} is not a tutor` });
      }

      if (!req.file) {
        return res.status(400).json({ message: "No file uploaded" });
      }

      const verificationPhotoPath = await uploadImageToObjectStorage(req.file, "verification");
      await updateTutorVerificationPhoto(userId, verificationPhotoPath);

      res.status(200).json({
        message: "Successfully updated prompt pay picture",
        profilePicture: verificationPhotoPath
      });
    } catch (err: any) {
      console.error("Error uploading verification picture", err);
      res.status(500).json({
        message: err?.message || "Error uploading verification picture",
      });
    }
  }
);

tutorService.post("/bio", verifyToken, async (req, res) => {
  const authData = req.body.authData;
  const userId = authData.userId;
  const role = authData.role;
  const bio = req.body.bio;
  try {
    if (role != "tutor") throw new Error(`This user ${userId} is not a tutor`);
    await updateTutorBio(userId, bio)
    res.status(200).json({message: "Successfully updated bio"});
  } catch (err) {
    res.status(500).json({message: "Error bio"});
  }
})

tutorService.post("/preferredPlace", verifyToken, async (req, res) => {
  const authData = req.body.authData;
  const userId = authData.userId;
  const role = authData.role;
  const preferred_place = req.body.preferred_place;
  try {
    if (role != "tutor") throw new Error(`This user ${userId} is not a tutor`);
    await updateTutorPreferredPlace(userId, preferred_place)
    res.status(200).json({message: "Successfully updated preferred place"});
  } catch (err) {
    res.status(500).json({message: "Error bio"});
  }
})

tutorService.patch("/location", verifyToken, async (req, res) => {
  const authData = req.body.authData;
  const userId = authData.userId;
  const role = authData.role;
  const province = req.body.province;
  const location = req.body.location;
  try {
    if (role != "tutor") throw new Error(`This user ${userId} is not a tutor`);
    await updateTutorLocation(userId, province, location);
    res.status(200).json({message: "Successfully updated location"});
  } catch (err) {
    res.status(500).json({message: "Error bio"});
  }
})

// Subjects
tutorService.get("/subjects/:userId", async (req, res) => {
  const params = req.params;
  const userId = params.userId;
  try {
    const tutorSubjects = await getTutorSubjects(userId);
    res.status(200).json(tutorSubjects);
  } catch (err) {
    res.status(404).json({message: "Account not found"});
  }
})

tutorService.post("/subjects/", verifyToken, async (req, res) => {
  const authData = req.body.authData;
  const userId = authData.userId;
  const role = authData.role;
  const subject = req.body.subject;
  const price = req.body.price;
  try {
    if (role != "tutor") throw new Error(`This user ${userId} is not a tutor`);
    await addTutorSubject(userId, subject, price);
    res.status(200).json({message: "Successfully added tutor subject"});
  } catch (err) {
    res.status(500).json({message: "Error bio"});
  }
})

tutorService.patch("/subjects/", verifyToken, async (req, res) => {
  const authData = req.body.authData;
  const userId = authData.userId;
  const role = authData.role;
  const subject = req.body.subject;
  const price = req.body.price;
  try {
    if (role != "tutor") throw new Error(`This user ${userId} is not a tutor`);
    await updateTutorSubjectPrice(userId, subject, price);
    res.status(200).json({message: "Successfully updated tutor subject"});
  } catch (err) {
    res.status(500).json({message: "Error bio"});
  }
})

tutorService.delete("/subjects/", verifyToken, async (req, res) => {
  const authData = req.body.authData;
  const userId = authData.userId;
  const role = authData.role;
  const subject = req.body.subject;
  try {
    if (role != "tutor") throw new Error(`This user ${userId} is not a tutor`);
    await deleteTutorSubject(userId, subject);
    res.status(200).json({message: "Successfully deleted tutor subject"});
  } catch (err) {
    res.status(500).json({message: "Error bio"});
  }
})

export default tutorService
