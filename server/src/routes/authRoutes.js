import express from "express";
import { register, login, logout, loginOnBrowser} from "../controllers/authController.js";

const router = express.Router();

router.post("/register", register);
router.post("/login", login);
router.post("/logout", logout);


router.get("/test-login", loginOnBrowser)
export default router;
