"use strict";

const visitorForm = document.getElementById("visitor-form");
const checkButton = document.getElementById("check-button");

async function checkBackend() {
  const statusElement = document.getElementById("status");

  statusElement.className = "";
  statusElement.textContent = "בודק את החיבור ל־Backend...";
  checkButton.disabled = true;

  try {
    const response = await fetch("/api/health");

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();

    statusElement.className = "success";
    statusElement.textContent =
      `החיבור הצליח — Service: ${data.service} | Status: ${data.status}`;
  } catch (error) {
    statusElement.className = "error";
    statusElement.textContent =
      `החיבור נכשל: ${error.message}`;
  } finally {
    checkButton.disabled = false;
  }
}

async function saveVisitor(event) {
  event.preventDefault();

  const nameInput = document.getElementById("visitor-name");
  const ageInput = document.getElementById("visitor-age");
  const messageElement = document.getElementById("form-message");
  const submitButton = document.getElementById("submit-button");

  messageElement.className = "form-message";
  messageElement.textContent = "שומר את הפרטים...";
  submitButton.disabled = true;

  try {
    const response = await fetch("/api/visitors", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        name: nameInput.value.trim(),
        age: Number(ageInput.value)
      })
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || `HTTP ${response.status}`);
    }

    messageElement.className = "form-message success";
    messageElement.textContent =
      `הפרטים נשמרו בהצלחה. מספר הרשומה: ${data.id}`;

    visitorForm.reset();
  } catch (error) {
    messageElement.className = "form-message error";
    messageElement.textContent =
      `שמירת הפרטים נכשלה: ${error.message}`;
  } finally {
    submitButton.disabled = false;
  }
}

checkButton.addEventListener("click", checkBackend);
visitorForm.addEventListener("submit", saveVisitor);