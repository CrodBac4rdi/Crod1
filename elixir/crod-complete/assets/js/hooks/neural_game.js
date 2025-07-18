// Neural Game Hook - Interactive CROD visualization
export default {
  mounted() {
    this.canvas = this.el
    this.rect = this.canvas.getBoundingClientRect()
    
    // Handle clicks with proper coordinates
    this.el.addEventListener('click', (e) => {
      const x = e.clientX - this.rect.left
      const y = e.clientY - this.rect.top
      
      this.pushEvent('canvas_click', {
        offsetX: x,
        offsetY: y
      })
      
      // Local visual feedback
      this.createRipple(x, y)
    })
    
    // Trinity explosion effect
    this.handleEvent("trinity_explosion", () => {
      this.triggerTrinityEffect()
    })
  },
  
  createRipple(x, y) {
    const ripple = document.createElement('div')
    ripple.className = 'absolute w-16 h-16 border-2 border-green-400 rounded-full animate-ping pointer-events-none'
    ripple.style.left = `${x - 32}px`
    ripple.style.top = `${y - 32}px`
    
    this.canvas.appendChild(ripple)
    
    setTimeout(() => ripple.remove(), 1000)
  },
  
  triggerTrinityEffect() {
    // Create multiple expanding rings
    for (let i = 0; i < 5; i++) {
      setTimeout(() => {
        const explosion = document.createElement('div')
        explosion.className = 'absolute inset-0 border-4 border-yellow-400 rounded-full animate-ping'
        explosion.style.animationDuration = '2s'
        
        this.canvas.appendChild(explosion)
        setTimeout(() => explosion.remove(), 2000)
      }, i * 200)
    }
    
    // Flash the background
    this.canvas.classList.add('animate-pulse', 'bg-gradient-to-r', 'from-red-900', 'via-yellow-900', 'to-green-900')
    setTimeout(() => {
      this.canvas.classList.remove('animate-pulse', 'bg-gradient-to-r', 'from-red-900', 'via-yellow-900', 'to-green-900')
    }, 3000)
  }
}