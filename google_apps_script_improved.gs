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
    // Check if report already exists for this worker and date
    const workerId = String(data.workerId || '');
    const reportDate = data.date || '';
    
    // Helper function to normalize date to YYYY-MM-DD format
    function normalizeDate(dateValue) {
      if (!dateValue) return '';
      
      // If it's a Date object
      if (dateValue instanceof Date) {
        const year = dateValue.getFullYear();
        const month = String(dateValue.getMonth() + 1).padStart(2, '0');
        const day = String(dateValue.getDate()).padStart(2, '0');
        return year + '-' + month + '-' + day;
      }
      
      // If it's a string, extract YYYY-MM-DD part
      const dateStr = String(dateValue);
      // Try to extract date part (handles formats like "2025-11-17", "2025-11-17T18:30:00", etc.)
      const match = dateStr.match(/(\d{4}-\d{2}-\d{2})/);
      if (match) {
        return match[1];
      }
      
      return dateStr.split('T')[0].split(' ')[0];
    }
    
    // Normalize the incoming report date
    const normalizedReportDate = normalizeDate(reportDate);
    
    const rows = sheetReports.getDataRange().getValues();
    let reportRowIndex = -1;
    let foundDuplicate = false;
    
    // Check all existing reports for this worker
    for (let i = 1; i < rows.length; i++) {
      const storedWorkerId = String(rows[i][0] || '');
      
      // Only check reports for the same worker
      if (storedWorkerId === workerId) {
        const storedDate = rows[i][2]; // Could be Date object or string
        const normalizedStoredDate = normalizeDate(storedDate);
        
        // Compare normalized dates
        if (normalizedStoredDate === normalizedReportDate) {
          reportRowIndex = i + 1; // +1 because sheet rows are 1-indexed
          foundDuplicate = true;
          break;
        }
      }
    }
    
    // If report exists, return error - use updateReport action to edit
    if (foundDuplicate) {
      return sendJSON({ 
        status: 'error', 
        success: false,
        message: 'A report for this date already exists. Only one submission per day is allowed. Please use the edit function to update it.',
        alreadyExists: true
      });
    }
    
    // Create new report only if one doesn't exist
    const timestamp = new Date();
    const reportData = [
      data.workerId,
      data.name || '',
      data.date,
      data.completed || '',
      data.inprogress || '',
      data.nextsteps || '',
      data.issues || '',
      JSON.stringify(data.students || []),
      timestamp,
    ];
    
    sheetReports.appendRow(reportData);
    return sendJSON({ status: 'submitted', success: true, updated: false });
  }

  if (action === 'updateReport') {
    // Update a specific report by workerId and date
    const workerId = String(data.workerId || '');
    const reportDate = data.date || '';
    const rows = sheetReports.getDataRange().getValues();
    let reportRowIndex = -1;
    
    for (let i = 1; i < rows.length; i++) {
      const storedWorkerId = String(rows[i][0] || '');
      const storedDate = String(rows[i][2] || '').split('T')[0];
      if (storedWorkerId === workerId && storedDate === reportDate.split('T')[0]) {
        reportRowIndex = i + 1;
        break;
      }
    }
    
    if (reportRowIndex > 0) {
      const timestamp = new Date();
      const reportData = [
        data.workerId,
        data.name || '',
        data.date,
        data.completed || '',
        data.inprogress || '',
        data.nextsteps || '',
        data.issues || '',
        JSON.stringify(data.students || []),
        timestamp,
      ];
      const range = sheetReports.getRange(reportRowIndex, 1, 1, reportData.length);
      range.setValues([reportData]);
      return sendJSON({ status: 'success', message: 'Report updated successfully' });
    } else {
      return sendJSON({ status: 'error', message: 'Report not found' });
    }
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
        const timestamp = rows[i][8]; // Column I (9th column, 0-indexed is 8)
        const storedDate = rows[i][2];
        
        // Normalize date to string format (YYYY-MM-DD) to avoid timezone issues
        let dateString = '';
        if (storedDate instanceof Date) {
          const year = storedDate.getFullYear();
          const month = String(storedDate.getMonth() + 1).padStart(2, '0');
          const day = String(storedDate.getDate()).padStart(2, '0');
          dateString = year + '-' + month + '-' + day;
        } else {
          // If it's already a string, extract just the date part
          const dateStr = String(storedDate || '');
          const match = dateStr.match(/(\d{4}-\d{2}-\d{2})/);
          dateString = match ? match[1] : dateStr.split('T')[0].split(' ')[0];
        }
        
        result.push({
          workerId: rows[i][0],
          name: rows[i][1] || '',
          date: dateString, // Return as YYYY-MM-DD string
          status: 'submitted', // Mark as submitted since it exists in the sheet
          completed: rows[i][3] || '',
          inprogress: rows[i][4] || '',
          nextsteps: rows[i][5] || '',
          issues: rows[i][6] || '',
          students: JSON.parse(rows[i][7] || '[]'),
          timestamp: timestamp ? timestamp.toISOString() : null,
        });
      }
    }
    return sendJSON({ status: 'success', reports: result });
  }

  if (action === 'getAllReports') {
    const rows = sheetReports.getDataRange().getValues();
    const result = [];
    for (let i = 1; i < rows.length; i++) {
      const storedDate = rows[i][2];
      
      // Normalize date to string format (YYYY-MM-DD) to avoid timezone issues
      let dateString = '';
      if (storedDate instanceof Date) {
        const year = storedDate.getFullYear();
        const month = String(storedDate.getMonth() + 1).padStart(2, '0');
        const day = String(storedDate.getDate()).padStart(2, '0');
        dateString = year + '-' + month + '-' + day;
      } else {
        // If it's already a string, extract just the date part
        const dateStr = String(storedDate || '');
        const match = dateStr.match(/(\d{4}-\d{2}-\d{2})/);
        dateString = match ? match[1] : dateStr.split('T')[0].split(' ')[0];
      }
      
      const timestamp = rows[i][8]; // Column I (9th column, 0-indexed is 8)
      
      result.push({
        workerId: rows[i][0] || '',
        name: rows[i][1] || '',
        workerName: rows[i][1] || '', // Alias for compatibility
        date: dateString, // Return as YYYY-MM-DD string
        status: 'submitted', // Mark as submitted since it exists in the sheet
        completed: rows[i][3] || '',
        tasksCompleted: rows[i][3] || '', // Alias for compatibility
        inprogress: rows[i][4] || '',
        tasksInProgress: rows[i][4] || '', // Alias for compatibility
        nextsteps: rows[i][5] || '',
        nextSteps: rows[i][5] || '', // Alias for compatibility
        issues: rows[i][6] || '',
        students: JSON.parse(rows[i][7] || '[]'),
        timestamp: timestamp ? timestamp.toISOString() : null,
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

