function doPost(e) {
  const data = JSON.parse(e.postData.contents || '{}');
  const action = data.action;
  const sheetWorkers = SpreadsheetApp.getActive().getSheetByName('Workers');
  const sheetReports = SpreadsheetApp.getActive().getSheetByName('Reports');

  if (action === 'register') {
    const workerId = Date.now().toString();
    sheetWorkers.appendRow([
      workerId,
      data.name,
      data.email,
      data.phone || '',
      data.password,
      new Date(),
    ]);
    return sendJSON({ status: 'success', workerId });
  }

  if (action === 'login') {
    // Normalize input email and password (trim and lowercase email)
    const inputEmail = (data.email || '').toString().trim().toLowerCase();
    const inputPassword = (data.password || '').toString().trim();
    
    const rows = sheetWorkers.getDataRange().getValues();
    for (let i = 1; i < rows.length; i++) {
      // Normalize stored email and password for comparison
      const storedEmail = (rows[i][2] || '').toString().trim().toLowerCase();
      const storedPassword = (rows[i][4] || '').toString().trim();
      
      if (storedEmail === inputEmail && storedPassword === inputPassword) {
        return sendJSON({
          status: 'success',
          workerId: rows[i][0],
          name: rows[i][1],
        });
      }
    }
    return sendJSON({ status: 'error', message: 'Invalid login credentials' });
  }

  if (action === 'submitReport') {
    sheetReports.appendRow([
      data.workerId,
      data.name || '',
      data.date,
      data.completed,
      data.inprogress,
      data.nextsteps,
      data.issues,
      JSON.stringify(data.students || []),
      new Date(),
    ]);
    return sendJSON({ status: 'submitted' });
  }

  if (action === 'getWorkerReports') {
    // Convert workerId to string for comparison (handles both string and number types)
    const workerId = String(data.workerId || '');
    const rows = sheetReports.getDataRange().getValues();
    const result = [];
    for (let i = 1; i < rows.length; i++) {
      // Convert stored workerId to string for comparison
      const storedWorkerId = String(rows[i][0] || '');
      if (storedWorkerId === workerId) {
        result.push({
          workerId: rows[i][0],
          name: rows[i][1] || '',
          date: rows[i][2] || '',
          status: 'submitted', // Mark as submitted since it exists in the sheet
          completed: rows[i][3] || '',
          inprogress: rows[i][4] || '',
          nextsteps: rows[i][5] || '',
          issues: rows[i][6] || '',
          students: JSON.parse(rows[i][7] || '[]'),
        });
      }
    }
    return sendJSON({ status: 'success', reports: result });
  }

  if (action === 'getAllReports') {
    const rows = sheetReports.getDataRange().getValues();
    const result = [];
    for (let i = 1; i < rows.length; i++) {
      result.push({
        workerId: rows[i][0] || '',
        name: rows[i][1] || '',
        date: rows[i][2] || '',
        status: 'submitted', // Mark as submitted since it exists in the sheet
        completed: rows[i][3] || '',
        inprogress: rows[i][4] || '',
        nextsteps: rows[i][5] || '',
        issues: rows[i][6] || '',
        students: JSON.parse(rows[i][7] || '[]'),
      });
    }
    return sendJSON({ status: 'success', reports: result });
  }

  return sendJSON({ status: 'error', message: 'Unknown action' });
}

function sendJSON(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

