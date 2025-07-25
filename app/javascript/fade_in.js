document.addEventListener('DOMContentLoaded', () => {
    const observer = new window.IntersectionObserver(
        (entries, observer) => {
            console.log(entries)
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    fadeIn(entry.target);
                    observer.unobserve(entry.target);
                }
            });
        }, {
        threshold: 0.1
    });
    
    document.querySelectorAll('.fade-in').forEach(element => {
        element.style.opacity = 0;
        observer.observe(element);
    });

    function fadeIn(element, duration = 1500) {
        let start = null;
        function step(timestamp) {
            if (!start) start = timestamp;
            const elapsed = timestamp - start;

            const progress = Math.min(elapsed / duration, 1);
            element.style.opacity = progress;
            if (progress < 1) {
                requestAnimationFrame(step);
            }
        }
        
        requestAnimationFrame(step);
    }
});