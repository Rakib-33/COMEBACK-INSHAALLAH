import 'dart:convert';

/// Injected helpers for [flutter_inappwebview] against **student.mist.ac.bd** (Uniplex).
/// Tuned for: `/login`, `/running-course`, course `.../assessments`.
class UniplexScripts {
  UniplexScripts._();

  /// Fills the login form (Material-style username + password) and taps **Login**.
  static String autoLogin({
    required String studentId,
    required String password,
  }) {
    final uLit = jsonEncode(studentId);
    final pLit = jsonEncode(password);
    return '''
(function(){
  function fire(el){ if(!el) return; el.dispatchEvent(new Event('input',{bubbles:true})); el.dispatchEvent(new Event('change',{bubbles:true})); el.dispatchEvent(new Event('blur',{bubbles:true})); }
  function setVal(el, v){ if(!el) return false; try{ el.focus(); }catch(e){} el.value = v; fire(el); return true; }
  var u = $uLit;
  var pw = $pLit;

  var passEl = document.querySelector('input[type="password"]');
  var userEl = null;

  var forms = document.querySelectorAll('form');
  if (forms.length){
    var ins = forms[0].querySelectorAll('input');
    for (var i=0;i<ins.length;i++){
      var ty = (ins[i].type || '').toLowerCase();
      if (ty === 'password' || ty === 'hidden' || ty === 'submit' || ty === 'button') continue;
      userEl = ins[i];
      break;
    }
  }
  if (!userEl) {
    userEl = document.querySelector('input[name="username"]')
      || document.querySelector('input[name="email"]')
      || document.querySelector('input[id="username"]')
      || document.querySelector('input[type="text"]')
      || document.querySelector('input:not([type])');
  }

  var hitUser = setVal(userEl, u);
  var hitPass = setVal(passEl, pw);

  var btn = null;
  var bs = document.querySelectorAll('button');
  for (var j=0;j<bs.length;j++){
    var t = (bs[j].innerText||'').trim();
    if (t.toLowerCase() === 'login') { btn = bs[j]; break; }
  }
  if (!btn) {
    btn = document.querySelector('button[type="submit"]')
      || document.querySelector('input[type="submit"]')
      || document.querySelector('form button');
  }

  var clicked = false;
  if (btn && hitUser && hitPass) {
    setTimeout(function(){ try { btn.click(); clicked = true; } catch(e){} }, 450);
  }
  return JSON.stringify({ok:true, hitUser:hitUser, hitPass:hitPass, clicked:clicked});
})();
''';
  }

  /// Running Courses grid (`/running-course`): cards with code **CSE-213**, title, **Theory, 3 Credit** / **Sessional, 1.5 Credit**.
  static const String extractCourseStubs = r'''
(function(){
  var text = document.body.innerText || '';
  // Match: Code -> Name (lazy) -> Theory/Sessional, X Credit
  var regex = /([A-Z]{2,4}[-\s]?\d{3})\s+([\s\S]{2,100}?)\s+(Theory|Sessional)\s*,\s*([\d.]+)\s*Credit/gi;
  var results = [];
  var seen = {};
  var match;
  
  while ((match = regex.exec(text)) !== null) {
    // Normalize code (e.g. "CSE 215" -> "CSE-215")
    var code = match[1].replace(/\s+/g, '-').toUpperCase();
    if (code.indexOf('-') === -1) {
      code = code.replace(/([A-Z]+)(\d+)/, '$1-$2');
    }
    
    if (seen[code]) continue;
    seen[code] = 1;
    
    // Clean up name (replace multiple newlines/spaces with a single space)
    var name = match[2].replace(/\s+/g, ' ').trim();
    var kind = match[3];
    var credits = parseFloat(match[4]) || 0;
    
    results.push({
      code: code,
      name: name,
      courseKind: kind,
      credits: credits,
      href: ''
    });
  }

  return JSON.stringify({ok:true, courses: results, href: location.href, title: document.title});
})();
''';

  /// Assessment page (`/running-course/{sem}/{course}/assessments`):
  /// Returns individual rows: `[{"name":"CT-1","score":16.0}, ...]`
  /// Column layout: SL(0) | Assessment(1) | Highest Marks(2) | Obtained Marks(3) | OBE(4) | Submitted By(5)
  /// The obtained marks cell contains "16/20", "14.5/20" — we take the numerator.
  /// Also calls `window.flutter_inappwebview.callHandler('syncMarks', jsonData)`.
  static const String extractAssessmentRows = r'''
(function(){
  function parseObtained(text) {
    var s = (text || '').trim();
    // Handle "16/20", "14.5/20", "17.75/20"
    var slashIdx = s.indexOf('/');
    if (slashIdx > 0) {
      var num = parseFloat(s.substring(0, slashIdx).trim());
      return isNaN(num) ? 0.0 : num;
    }
    // Handle plain numbers or N/A
    var n = parseFloat(s);
    return isNaN(n) ? 0.0 : n;
  }

  var CODE = /([A-Z]{2,4}-\d{3}|[A-Z]{2,4}\s*\d{3}|[A-Z]{2,4}\d{3})/i;
  function normCode(raw){
    var s = (raw||'').replace(/\s+/g,'').toUpperCase();
    var m = s.match(/([A-Z]{2,4})-?(\d{3})/);
    if (m) return m[1] + '-' + m[2];
    return s;
  }

  // Find course code from page text
  var pageText = document.body.innerText || '';
  var mCode = pageText.match(CODE);
  var courseCode = mCode ? normCode(mCode[0]) : '';

  var rows = [];
  var tables = document.querySelectorAll('table');

  for (var ti = 0; ti < tables.length; ti++) {
    var table = tables[ti];
    // Prefer tbody rows; fallback to all tr
    var trs = table.querySelectorAll('tbody tr');
    if (!trs || trs.length === 0) {
      trs = table.querySelectorAll('tr');
    }

    // Verify this is the correct table by checking if it contains "Assessment" or "Obtained"
    var tableText = table.innerText || '';
    if (tableText.toLowerCase().indexOf('obtained') === -1 && tableText.toLowerCase().indexOf('assessment') === -1) {
      continue;
    }

    var nameCol = -1;
    var scoreCol = -1;

    // Find headers
    var headers = table.querySelectorAll('th, td');
    for (var i = 0; i < headers.length; i++) {
      var txt = (headers[i].innerText || '').toLowerCase().trim();
      if (txt === 'assessment') nameCol = i;
      else if (txt.indexOf('obtained') !== -1) scoreCol = i;
      
      // Stop checking if we crossed the first row
      if (headers[i].parentNode !== headers[0].parentNode) break;
    }

    // Default fallbacks if not found
    if (nameCol === -1) nameCol = 1;
    if (scoreCol === -1) scoreCol = 3;

    var found = false;
    for (var ri = 0; ri < trs.length; ri++) {
      var tds = trs[ri].querySelectorAll('td');
      if (tds.length <= Math.max(nameCol, scoreCol)) continue;

      var nameRaw = tds[nameCol] ? (tds[nameCol].innerText || '') : '';
      var nameLine = nameRaw.split('\n')[0].trim();
      if (!nameLine) continue;
      
      var nl = nameLine.toLowerCase();
      if (nl === 'assessment' || nl === 'sl' || nl === 'no' || nl === 'no.' || nl === 'highest marks' || nl === 'obtained marks') continue;

      var obtainedRaw = tds[scoreCol] ? (tds[scoreCol].innerText || '').trim() : '';
      var score = parseObtained(obtainedRaw);

      if (nameLine.length > 0) {
        rows.push({ name: nameLine, score: score });
        found = true;
      }
    }
    if (found) break; // stop after first table with data
  }

  var payload = JSON.stringify({ ok: true, rows: rows, courseCode: courseCode, href: location.href });

  // Bridge to Flutter
  if (window.flutter_inappwebview) {
    window.flutter_inappwebview.callHandler('syncMarks', payload);
  }

  return payload;
})();
''';

  /// Semester label from filter (e.g. Fall 2025) or page text.
  static const String extractSemesterHint = r'''
(function(){
  var txt = (document.body && document.body.innerText) ? document.body.innerText : '';
  var m = txt.match(/(Spring|Summer|Fall|Autumn)\s+20\d{2}/i);
  return JSON.stringify({ok:true, label: m ? m[0] : ''});
})();
''';
}
