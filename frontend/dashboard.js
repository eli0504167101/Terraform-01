"use strict";

const adminForm = document.getElementById("admin-form");
const tokenInput = document.getElementById("admin-token");
const loadButton = document.getElementById("load-button");
const messageElement = document.getElementById("dashboard-message");
const resultsSection = document.getElementById("results-section");
const tableBody = document.getElementById("visitors-table-body");
const visitorCount = document.getElementById("visitor-count");

function createTableCell(value) {
  const cell = document.createElement("td");
  cell.textContent = value;
  return cell;
}

function renderVisitors(visitors) {
  tableBody.replaceChildren();

  for (const visitor of visitors) {
    const row = document.createElement("tr");

    const createdAt = new Date(visitor.created_at)
      .toLocaleString("he-IL");

    row.append(
      createTableCell(visitor.id),
      createTableCell(visitor.name),
      createTableCell(visitor.age),
      createTableCell(createdAt)
    );

    tableBody.appendChild(row);
  }

  visitorCount.textContent = `${visitors.length} רשומות`;
  resultsSection.hidden = false;
}

async function loadVisitors(event) {
  event.preventDefault();

  const token = tokenInput.value.trim();

  messageElement.className = "form-message";
  messageElement.textContent = "טוען רשומות...";
  loadButton.disabled = true;
  resultsSection.hidden = true;

  try {
    const response = await fetch("/api/visitors", {
      headers: {
        "X-Admin-Token": token
      }
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || `HTTP ${response.status}`);
    }

    renderVisitors(data.visitors);

    messageElement.className = "form-message success";
    messageElement.textContent = "הרשומות נטענו בהצלחה.";
  } catch (error) {
    messageElement.className = "form-message error";
    messageElement.textContent =
      `טעינת הרשומות נכשלה: ${error.message}`;
  } finally {
    loadButton.disabled = false;
  }
}

adminForm.addEventListener("submit", loadVisitors);