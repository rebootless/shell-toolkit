(function() {
  // --- Live text filter, applied to both the summary table AND the detailed
  // script cards below it, so the two views never disagree. ---
  var input = document.getElementById('script-filter');
  var resetBtn = document.getElementById('filter-reset');
  var hint = document.getElementById('filter-hint');
  var rows = Array.prototype.slice.call(document.querySelectorAll('#all-scripts-table tbody tr'));
  var cards = Array.prototype.slice.call(document.querySelectorAll('.script-card'));
  var dirHeadings = Array.prototype.slice.call(document.querySelectorAll('.dir-heading'));

  function matches(el, q) {
    return !q || (el.getAttribute('data-search') || '').indexOf(q) !== -1;
  }

  function applyFilters() {
    var q = input ? input.value.trim().toLowerCase() : '';
    var shown = 0;
    rows.forEach(function(row) {
      var match = matches(row, q);
      row.classList.toggle('filtered-out', !match);
      if (match) shown++;
    });
    cards.forEach(function(card) {
      card.classList.toggle('filtered-out', !matches(card, q));
    });
    // Hide a directory heading once every card underneath it is filtered out.
    dirHeadings.forEach(function(heading) {
      var sib = heading.nextElementSibling;
      var anyVisible = false;
      while (sib && !sib.classList.contains('dir-heading')) {
        if (sib.classList.contains('script-card') && !sib.classList.contains('filtered-out')) {
          anyVisible = true;
        }
        sib = sib.nextElementSibling;
      }
      heading.classList.toggle('filtered-out', !anyVisible);
    });
    if (hint) hint.textContent = q ? (shown + ' of ' + rows.length + ' scripts match') : '';
  }

  if (input) input.addEventListener('input', applyFilters);
  if (resetBtn) {
    resetBtn.addEventListener('click', function() {
      if (input) input.value = '';
      applyFilters();
      if (input) input.focus();
    });
  }
  applyFilters();

  // --- Sortable summary table: click a sortable header to sort by that column. ---
  var table = document.getElementById('all-scripts-table');
  if (table) {
    var tbody = table.querySelector('tbody');
    var sortState = { col: null, dir: 1 };
    Array.prototype.slice.call(table.querySelectorAll('th.sortable')).forEach(function(th) {
      th.addEventListener('click', function() {
        var col = parseInt(th.getAttribute('data-col'), 10);
        var type = th.getAttribute('data-type');
        sortState.dir = (sortState.col === col) ? -sortState.dir : 1;
        sortState.col = col;

        Array.prototype.slice.call(table.querySelectorAll('th.sortable')).forEach(function(h) {
          h.classList.remove('sort-asc', 'sort-desc');
        });
        th.classList.add(sortState.dir === 1 ? 'sort-asc' : 'sort-desc');

        var sorted = rows.slice().sort(function(a, b) {
          var av = a.children[col].getAttribute('data-value') || '';
          var bv = b.children[col].getAttribute('data-value') || '';
          if (type === 'num') {
            return (parseFloat(av) - parseFloat(bv)) * sortState.dir;
          }
          return av.localeCompare(bv) * sortState.dir;
        });
        sorted.forEach(function(row) { tbody.appendChild(row); });
      });
    });
  }

  // --- Copy-path buttons on each script card ---
  document.querySelectorAll('.copy-btn').forEach(function(btn) {
    btn.addEventListener('click', function() {
      var path = btn.getAttribute('data-path');
      var reset = function() { btn.classList.remove('copied'); btn.title = 'Copy path'; };
      var onCopied = function() {
        btn.classList.add('copied');
        btn.title = 'Copied!';
        setTimeout(reset, 1200);
      };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(path).then(onCopied, function() {});
      } else {
        var tmp = document.createElement('textarea');
        tmp.value = path;
        tmp.style.position = 'fixed';
        tmp.style.opacity = '0';
        document.body.appendChild(tmp);
        tmp.select();
        try { document.execCommand('copy'); onCopied(); } catch (e) {}
        document.body.removeChild(tmp);
      }
    });
  });

  // --- Scrollspy: highlight the current section in the TOC while scrolling ---
  var tocLinks = Array.prototype.slice.call(document.querySelectorAll('.toc a[href^="#"]'));
  var targets = tocLinks
    .map(function(a) {
      var id = a.getAttribute('href').slice(1);
      var el = document.getElementById(id);
      return el ? { link: a, el: el } : null;
    })
    .filter(Boolean);

  function onScroll() {
    var pos = window.scrollY + 110;
    var current = null;
    targets.forEach(function(t) {
      if (t.el.offsetTop <= pos) current = t;
    });
    tocLinks.forEach(function(a) { a.classList.remove('active'); });
    if (current) current.link.classList.add('active');
  }
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();
})();
