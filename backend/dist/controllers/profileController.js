import { asyncHandler } from '../middleware/asyncHandler.js';
import { getProfile, updateProfile, updateLastActiveAt, saveProfileImage, getProfileImageRaw } from '../services/profileService.js';
import { db } from '../db/pool.js';
export const getProfileHandler = asyncHandler(async (req, res) => {
    const userId = req.userId;
    const profile = await getProfile(userId);
    if (!profile) {
        res.status(404).json({ success: false, error: 'User not found' });
        return;
    }
    res.json({ success: true, data: profile });
});
export const updateProfileHandler = asyncHandler(async (req, res) => {
    const userId = req.userId;
    const body = req.body;
    const payload = {};
    if (body.fullName !== undefined)
        payload.fullName = String(body.fullName);
    if (body.phoneNumber !== undefined)
        payload.phoneNumber = String(body.phoneNumber);
    if (body.businessName !== undefined)
        payload.businessName = String(body.businessName);
    if (body.category !== undefined)
        payload.category = String(body.category);
    if (body.tradeLicense !== undefined)
        payload.tradeLicense = String(body.tradeLicense);
    if (body.minOrderValue !== undefined)
        payload.minOrderValue = Number(body.minOrderValue);
    if (body.supplyRadius !== undefined)
        payload.supplyRadius = String(body.supplyRadius);
    if (body.address !== undefined)
        payload.address = String(body.address);
    if (body.latitude !== undefined)
        payload.latitude = Number(body.latitude);
    if (body.longitude !== undefined)
        payload.longitude = Number(body.longitude);
    const profile = await updateProfile(userId, payload);
    if (!profile) {
        res.status(404).json({ success: false, error: 'User not found' });
        return;
    }
    res.json({ success: true, data: profile });
});
export const heartbeatHandler = asyncHandler(async (req, res) => {
    const userId = req.userId;
    await updateLastActiveAt(userId);
    res.json({ success: true });
});
export const uploadProfileImageHandler = asyncHandler(async (req, res) => {
    const userId = req.userId;
    const file = req.file;
    if (!file) {
        res.status(400).json({ success: false, error: 'No image file uploaded' });
        return;
    }
    await saveProfileImage(userId, file.mimetype, file.buffer);
    const host = req.get('host') || 'tradelink-2.onrender.com';
    const baseUrl = `https://${host}`;
    const profilePictureUrl = `${baseUrl}/profile-images/${userId}?v=${Date.now()}`;
    await db.query(`UPDATE users SET profile_picture_url = $1, updated_at = now() WHERE id = $2`, [profilePictureUrl, userId]);
    const profile = await getProfile(userId);
    res.json({ success: true, data: profile });
});
export const getProfileImageHandler = asyncHandler(async (req, res) => {
    const userId = String(req.params.id);
    const image = await getProfileImageRaw(userId);
    if (!image) {
        res.status(404).json({ success: false, error: 'Image not found' });
        return;
    }
    res.setHeader('Content-Type', image.mimeType);
    res.setHeader('Cache-Control', 'public, max-age=31536000');
    res.send(image.data);
});
//# sourceMappingURL=profileController.js.map