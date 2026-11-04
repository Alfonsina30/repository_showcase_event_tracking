const functions = require("firebase-functions");
const admin = require("firebase-admin");
// import FieldValue independently
const {FieldValue} = require("firebase-admin/firestore");


if (admin.apps.length === 0) {
  admin.initializeApp();
}
//  --------------------------------- CREATE COMPANY ADMIN -------------------
//  --------------------------------------------------------------------------
exports.createCompanyAdmin = functions.https.onRequest(async (reqst, resp)=> {
  let email;
  let uid;

  const authHeader = reqst.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return resp.status(401).json({
      error: {message: "Must be logged in.", status: "UNAUTHENTICATED"}});
  }

  try {
    const token = authHeader.split("Bearer ")[1];
    const verifiedToken = await admin.auth().verifyIdToken(token);
    uid = verifiedToken.uid;
    email = verifiedToken.email;
    console.log(`User successfully authenticated UID: ${uid}, Email: ${email}`);
  } catch (error) {
    console.error("Error verifying the token:", error);

    return resp.status(401).json({
      error: {message: "Invalid or expired token.", status: "UNAUTHENTICATED"},
    });
  }
  // The server decides the role for security reasons
  const assignedRole = "admin";
  const companyName = reqst.body.data.companyName;

  // --VALIDATING ARGUMENTS
  const data = reqst.body.data;
  if (!data || !data.companyName || data.companyName.trim() === "") {
    return resp.status(400).json({ // invalid arguments
      error: {
        message: "Company name is required.",
        status: "INVALID_ARGUMENT"},
    });
  }
  try {
    // Create the document companies with the uid
    await admin.firestore().collection("companies").
        doc(uid).set({
          name: companyName,
          createdAt: FieldValue.serverTimestamp(),
          ownerUid: uid,
        });

    // Set Custom Claims
    await admin.auth().setCustomUserClaims(uid, {
      role: assignedRole,
      companyId: uid,
    });

    // Save profile in Firestore
    await admin.firestore().collection("users").doc(uid).set({
      email: email,
      role: assignedRole,
      companyId: uid,
      createdAt: FieldValue.serverTimestamp(),
    });
    console.log(`Company created.${companyName}`);

    return resp.status(200).json({
      data: {success: true, message: uid}});
  } catch (serverError) {
    console.error("Internal Server Error during registration:", serverError);
    // Firestore fails or the network goes down, but the token is still valid.
    // It's a 500 error.
    return resp.status(500).json({
      error: {
        message: "Internal server error saving data.", status: "INTERNAL"},
    });
  }
});

// ------------------------------- REGISTER EMPLOYEE ---------------------------
//  ----------------------------------------------------------------------------
exports.registerEmployee = functions.https.onRequest(async (req, resp)=> {
  let adminUid;
  let secureCompanyId;

  const data = req.body.data;
  const emails = data.emails;
  const role = data.role || "role";
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return resp.status(401).json({
      error: {message: "Must be logged in.", status: "UNAUTHENTICATED"}});
  }

  if (!emails || !Array.isArray(emails) || emails.length === 0 ||
          !role || role.trim() === "") {
    return resp.status(400).json({
      error: {message: "Email is required.", status: "INVALID_ARGUMENT"},
    });
  }

  try {
  // ------------- ADMIN TOKEN -----
    const token = authHeader.split("Bearer ")[1];
    const verifiedToken = await admin.auth().verifyIdToken(token);
    adminUid = verifiedToken.uid;
    secureCompanyId = verifiedToken.companyId;

    if (verifiedToken.role !== "admin" || !secureCompanyId ) {
      return resp.status(403).json({
        error: {
          message: "Forbidden: Only admins can invite members.",
          status: "PERMISSION_DENIED"},
      });
    }
  } catch (error) {
    return resp.status(403).json({
      error: {
        message: "Forbidden: Only admins can invite members.",
        status: "PERMISSION_DENIED"},
    });
  }

  try {
  //  ----- INSERT INVITATIONS ------
    const db = admin.firestore();
    const batch = db.batch();
    const invitationsCollection = db.collection("invitations");
    emails.forEach((email)=>{
      const newDocRef = invitationsCollection.doc();
      batch.set(newDocRef, {
        companyId: secureCompanyId,
        email: email.toLowerCase().trim(),
        role: role,
        invitedBy: adminUid,
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    // running all executions
    await batch.commit();

    console.log(` invitations created successfully length ${emails.length}`);
    return resp.status(200).json({
      data: {
        success: true,
        message: `${emails.length} invitations created successfully`,

      },
    });
  } catch (error) {
    console.error("Error en registerEmployee:", error);
    return resp.status(500).json({
      error: {message: "Internal server error.", status: "INTERNAL"},
    });
  }
});

// create function for do a query to invitations collection
