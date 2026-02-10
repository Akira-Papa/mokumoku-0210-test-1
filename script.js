/* ================================================
   NexTech Solutions - Main Script
   ================================================ */

document.addEventListener('DOMContentLoaded', () => {

  /* ---------- HERO CANVAS (Particle Grid) ---------- */
  const canvas = document.getElementById('heroCanvas');
  if (canvas) {
    const ctx = canvas.getContext('2d');
    let w, h, particles, mouse;

    function initCanvas() {
      w = canvas.width = window.innerWidth;
      h = canvas.height = window.innerHeight;
      mouse = { x: w / 2, y: h / 2 };

      const cols = Math.floor(w / 60);
      const rows = Math.floor(h / 60);
      particles = [];

      for (let i = 0; i < cols; i++) {
        for (let j = 0; j < rows; j++) {
          particles.push({
            x: (i + 0.5) * (w / cols),
            y: (j + 0.5) * (h / rows),
            baseX: (i + 0.5) * (w / cols),
            baseY: (j + 0.5) * (h / rows),
            size: Math.random() * 1.5 + 0.5,
            alpha: Math.random() * 0.3 + 0.05,
          });
        }
      }
    }

    function drawCanvas() {
      ctx.clearRect(0, 0, w, h);

      particles.forEach(p => {
        const dx = mouse.x - p.x;
        const dy = mouse.y - p.y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        const maxDist = 200;

        if (dist < maxDist) {
          const force = (maxDist - dist) / maxDist;
          p.x -= dx * force * 0.02;
          p.y -= dy * force * 0.02;
        }

        p.x += (p.baseX - p.x) * 0.05;
        p.y += (p.baseY - p.y) * 0.05;

        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(0, 212, 255, ${p.alpha})`;
        ctx.fill();

        // Connect nearby particles
        particles.forEach(p2 => {
          const d = Math.hypot(p.x - p2.x, p.y - p2.y);
          if (d < 80 && d > 0) {
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
            ctx.lineTo(p2.x, p2.y);
            ctx.strokeStyle = `rgba(0, 212, 255, ${0.03 * (1 - d / 80)})`;
            ctx.lineWidth = 0.5;
            ctx.stroke();
          }
        });
      });

      requestAnimationFrame(drawCanvas);
    }

    canvas.addEventListener('mousemove', (e) => {
      mouse.x = e.clientX;
      mouse.y = e.clientY;
    });

    window.addEventListener('resize', initCanvas);
    initCanvas();
    drawCanvas();
  }


  /* ---------- NAV SCROLL ---------- */
  const nav = document.getElementById('nav');
  const handleNavScroll = () => {
    nav.classList.toggle('scrolled', window.scrollY > 50);
  };
  window.addEventListener('scroll', handleNavScroll, { passive: true });
  handleNavScroll();


  /* ---------- MOBILE MENU ---------- */
  const hamburger = document.getElementById('hamburger');
  const navLinks = document.getElementById('navLinks');

  hamburger.addEventListener('click', () => {
    hamburger.classList.toggle('active');
    navLinks.classList.toggle('open');
  });

  navLinks.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
      hamburger.classList.remove('active');
      navLinks.classList.remove('open');
    });
  });


  /* ---------- SCROLL REVEAL ---------- */
  const revealElements = document.querySelectorAll('.reveal');

  const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach((entry, index) => {
      if (entry.isIntersecting) {
        setTimeout(() => {
          entry.target.classList.add('visible');
        }, index * 80);
        revealObserver.unobserve(entry.target);
      }
    });
  }, {
    threshold: 0.1,
    rootMargin: '0px 0px -40px 0px',
  });

  revealElements.forEach(el => revealObserver.observe(el));


  /* ---------- COUNTER ANIMATION ---------- */
  const counters = document.querySelectorAll('.hero__stat-num');

  const counterObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const el = entry.target;
        const target = parseFloat(el.dataset.target);
        const isDecimal = target % 1 !== 0;
        const duration = 2000;
        const startTime = performance.now();

        function updateCounter(currentTime) {
          const elapsed = currentTime - startTime;
          const progress = Math.min(elapsed / duration, 1);

          // Ease out cubic
          const eased = 1 - Math.pow(1 - progress, 3);
          const current = target * eased;

          el.textContent = isDecimal ? current.toFixed(1) : Math.floor(current);

          if (progress < 1) {
            requestAnimationFrame(updateCounter);
          } else {
            el.textContent = isDecimal ? target.toFixed(1) : target;
          }
        }

        requestAnimationFrame(updateCounter);
        counterObserver.unobserve(el);
      }
    });
  }, { threshold: 0.5 });

  counters.forEach(el => counterObserver.observe(el));


  /* ---------- SMOOTH SCROLL ---------- */
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', (e) => {
      e.preventDefault();
      const target = document.querySelector(anchor.getAttribute('href'));
      if (target) {
        const offset = 72; // nav height
        const top = target.getBoundingClientRect().top + window.scrollY - offset;
        window.scrollTo({ top, behavior: 'smooth' });
      }
    });
  });


  /* ---------- CONTACT FORM ---------- */
  const form = document.getElementById('contactForm');
  if (form) {
    form.addEventListener('submit', (e) => {
      e.preventDefault();

      const btn = form.querySelector('button[type="submit"]');
      const originalText = btn.textContent;

      btn.textContent = '送信中...';
      btn.disabled = true;
      btn.style.opacity = '0.7';

      // Simulate submission
      setTimeout(() => {
        btn.textContent = '送信完了';
        btn.style.background = '#10b981';
        btn.style.opacity = '1';

        setTimeout(() => {
          form.reset();
          btn.textContent = originalText;
          btn.style.background = '';
          btn.disabled = false;
        }, 2500);
      }, 1500);
    });
  }

});
