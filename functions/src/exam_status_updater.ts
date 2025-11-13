import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';

// Initialize Firebase Admin
if (!admin.apps.length) {
    admin.initializeApp();
}

// Function to update exam statuses
export const updateExamStatuses = onSchedule('every 5 minutes', async (event): Promise<void> => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    try {
        // Get all pending exams
        const pendingExams = await db
            .collection('exams')
            .where('status', '==', 'Pending')
            .get();

        const batch = db.batch();
        let updateCount = 0;

        pendingExams.docs.forEach((doc) => {
            const exam = doc.data();
            const endDateTime = exam.endDateTime?.toDate();

            if (endDateTime && now.toDate() >= endDateTime) {
                batch.update(doc.ref, { 
                    status: 'Completed',
                    updatedAt: now
                });
                updateCount++;
            }
        });

        if (updateCount > 0) {
            await batch.commit();
            console.log(`Updated ${updateCount} exams to Completed status`);
        }

    } catch (error) {
        console.error('Error updating exam statuses:', error);
    }
});
