// Point this at your own n8n instance once it's deployed.
// Local testing default assumes n8n running via the Docker command in
// /n8n-workflows/README.md.
const RESLIFE_CONFIG = {
  QUOTE_WEBHOOK_URL: "http://localhost:5678/webhook/quote-request",
  MANAGER_APPROVE_WEBHOOK_URL: "http://localhost:5678/webhook/manager-approve"
};
