import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';

// Initialize Firebase Admin
admin.initializeApp();

// Email configuration interface
interface EmailConfig {
  smtpHost: string;
  smtpPort: number;
  smtpUsername: string;
  smtpPassword: string;
  useTLS: boolean;
  fromEmail: string;
  fromName: string;
  adminEmail: string;
}

// Email log interface
interface EmailLog {
  to: string;
  subject: string;
  body: string;
  htmlBody?: string;
  sentAt: string;
  status: string;
  error?: string;
}

/**
 * Cloud Function to send emails when email logs are created
 */
export const sendEmail = functions.firestore
  .document('email_logs/{emailId}')
  .onCreate(async (snap, context) => {
    const emailData = snap.data() as EmailLog;
    const emailId = context.params.emailId;

    try {
      // Get email configuration
      const configDoc = await admin.firestore()
        .collection('email_config')
        .doc('admin_config')
        .get();

      if (!configDoc.exists) {
        console.log('No email configuration found');
        await snap.ref.update({
          status: 'failed',
          error: 'No email configuration found',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        return;
      }

      const config = configDoc.data() as EmailConfig;

      // Create nodemailer transporter
      const transporter = nodemailer.createTransporter({
        host: config.smtpHost,
        port: config.smtpPort,
        secure: config.smtpPort === 465, // true for 465, false for other ports
        auth: {
          user: config.smtpUsername,
          pass: config.smtpPassword,
        },
        tls: {
          rejectUnauthorized: false
        }
      });

      // Email options
      const mailOptions = {
        from: `"${config.fromName}" <${config.fromEmail}>`,
        to: emailData.to,
        subject: emailData.subject,
        text: emailData.body,
        html: emailData.htmlBody || emailData.body,
      };

      // Send email
      const info = await transporter.sendMail(mailOptions);
      
      console.log('Email sent successfully:', info.messageId);

      // Update email log with success status
      await snap.ref.update({
        status: 'sent',
        messageId: info.messageId,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

    } catch (error) {
      console.error('Error sending email:', error);
      
      // Update email log with error status
      await snap.ref.update({
        status: 'failed',
        error: error instanceof Error ? error.message : 'Unknown error',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });

/**
 * Cloud Function to send issue report emails
 */
export const sendIssueReportEmail = functions.firestore
  .document('issue_reports/{reportId}')
  .onCreate(async (snap, context) => {
    const report = snap.data();
    const reportId = context.params.reportId;

    try {
      // Get email configuration
      const configDoc = await admin.firestore()
        .collection('email_config')
        .doc('admin_config')
        .get();

      if (!configDoc.exists) {
        console.log('No email configuration found for issue report');
        return;
      }

      const config = configDoc.data() as EmailConfig;

      // Generate email content
      const subject = `New Issue Report: ${report.title}`;
      const priorityColor = getPriorityColor(report.priority);
      
      const htmlBody = `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Issue Report</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: #f4f4f4; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
                .priority { display: inline-block; padding: 5px 10px; border-radius: 3px; color: white; font-weight: bold; }
                .content { background: white; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
                .field { margin-bottom: 15px; }
                .label { font-weight: bold; color: #666; }
                .value { margin-top: 5px; }
                .image { max-width: 100%; height: auto; border-radius: 5px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h2>New Issue Report</h2>
                    <span class="priority" style="background-color: ${priorityColor};">${report.priority.toUpperCase()}</span>
                </div>
                <div class="content">
                    <div class="field">
                        <div class="label">Title:</div>
                        <div class="value">${report.title}</div>
                    </div>
                    <div class="field">
                        <div class="label">Description:</div>
                        <div class="value">${report.description}</div>
                    </div>
                    <div class="field">
                        <div class="label">Reporter:</div>
                        <div class="value">${report.reporterName} (${report.reporterRole})</div>
                    </div>
                    <div class="field">
                        <div class="label">Location:</div>
                        <div class="value">Floor ${report.floor}, Door ${report.doorNumber}</div>
                    </div>
                    <div class="field">
                        <div class="label">Toilet Type:</div>
                        <div class="value">${report.toiletType}</div>
                    </div>
                    ${report.imageUrl ? `
                    <div class="field">
                        <div class="label">Image:</div>
                        <div class="value">
                            <img src="${report.imageUrl}" alt="Issue Image" class="image">
                        </div>
                    </div>
                    ` : ''}
                    <div class="field">
                        <div class="label">Reported At:</div>
                        <div class="value">${new Date(report.createdAt).toLocaleString()}</div>
                    </div>
                </div>
            </div>
        </body>
        </html>
      `;

      const textBody = `
New Issue Report

Title: ${report.title}
Priority: ${report.priority.toUpperCase()}

Description:
${report.description}

Reporter: ${report.reporterName} (${report.reporterRole})
Location: Floor ${report.floor}, Door ${report.doorNumber}
Toilet Type: ${report.toiletType}

Reported At: ${new Date(report.createdAt).toLocaleString()}

Please log into the admin dashboard to manage this report.
      `;

      // Create email log entry
      await admin.firestore().collection('email_logs').add({
        to: config.adminEmail,
        subject: subject,
        body: textBody,
        htmlBody: htmlBody,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'pending',
        reportId: reportId
      });

      console.log('Issue report email queued for sending');

    } catch (error) {
      console.error('Error processing issue report email:', error);
    }
  });

/**
 * Helper function to get priority color
 */
function getPriorityColor(priority: string): string {
  switch (priority.toLowerCase()) {
    case 'urgent': return '#dc3545';
    case 'high': return '#fd7e14';
    case 'medium': return '#ffc107';
    case 'low': return '#28a745';
    default: return '#6c757d';
  }
}
