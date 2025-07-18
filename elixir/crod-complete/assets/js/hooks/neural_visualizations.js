// Neural Network Visualization Hooks
// Using Chart.js, D3.js, and ECharts for professional data visualization

import Chart from 'chart.js/auto';
import * as d3 from 'd3';
import * as echarts from 'echarts';

// Neural Activity Chart Hook
export const NeuralActivityChart = {
  mounted() {
    this.initChart();
    this.handleEvent("update_activity", (data) => this.updateChart(data));
  },
  
  initChart() {
    const ctx = this.el.getContext('2d');
    const neurons = JSON.parse(this.el.dataset.neurons || '[]');
    const activity = JSON.parse(this.el.dataset.activity || '[]');
    
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: Array.from({length: 60}, (_, i) => i + 's'),
        datasets: [{
          label: 'Neural Activity',
          data: activity,
          borderColor: '#60A5FA',
          backgroundColor: 'rgba(96, 165, 250, 0.1)',
          fill: true,
          tension: 0.4,
          pointRadius: 0,
          pointHoverRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            max: 100,
            ticks: { color: '#9CA3AF' },
            grid: { color: 'rgba(156, 163, 175, 0.1)' }
          },
          x: {
            ticks: { color: '#9CA3AF' },
            grid: { color: 'rgba(156, 163, 175, 0.1)' }
          }
        },
        plugins: {
          legend: { labels: { color: '#9CA3AF' } }
        },
        animation: {
          duration: 200,
          easing: 'easeInOutQuart'
        }
      }
    });
  },
  
  updateChart(data) {
    if (this.chart) {
      this.chart.data.datasets[0].data = data.activity;
      this.chart.update('none');
    }
  },
  
  destroyed() {
    if (this.chart) this.chart.destroy();
  }
};

// Neural Network Topology Hook
export const NeuralTopology = {
  mounted() {
    this.initTopology();
    this.handleEvent("update_topology", (data) => this.updateTopology(data));
  },
  
  initTopology() {
    const nodes = JSON.parse(this.el.dataset.nodes || '[]');
    const connections = JSON.parse(this.el.dataset.connections || '[]');
    
    const width = this.el.offsetWidth;
    const height = this.el.offsetHeight;
    
    this.svg = d3.select(this.el)
      .append('svg')
      .attr('width', width)
      .attr('height', height);
    
    // Create force simulation
    this.simulation = d3.forceSimulation(nodes)
      .force('link', d3.forceLink(connections).id(d => d.id).distance(50))
      .force('charge', d3.forceManyBody().strength(-200))
      .force('center', d3.forceCenter(width / 2, height / 2));
    
    // Create links
    this.link = this.svg.append('g')
      .selectAll('line')
      .data(connections)
      .enter().append('line')
      .attr('stroke', '#374151')
      .attr('stroke-width', d => d.weight * 2);
    
    // Create nodes
    this.node = this.svg.append('g')
      .selectAll('circle')
      .data(nodes)
      .enter().append('circle')
      .attr('r', 8)
      .attr('fill', d => this.getNodeColor(d.activation))
      .call(d3.drag()
        .on('start', this.dragstarted.bind(this))
        .on('drag', this.dragged.bind(this))
        .on('end', this.dragended.bind(this)));
    
    // Add node labels
    this.label = this.svg.append('g')
      .selectAll('text')
      .data(nodes)
      .enter().append('text')
      .text(d => d.id)
      .attr('font-size', '10px')
      .attr('fill', '#9CA3AF')
      .attr('text-anchor', 'middle');
    
    this.simulation.on('tick', () => {
      this.link
        .attr('x1', d => d.source.x)
        .attr('y1', d => d.source.y)
        .attr('x2', d => d.target.x)
        .attr('y2', d => d.target.y);
      
      this.node
        .attr('cx', d => d.x)
        .attr('cy', d => d.y);
      
      this.label
        .attr('x', d => d.x)
        .attr('y', d => d.y + 4);
    });
  },
  
  getNodeColor(activation) {
    if (activation > 0.8) return '#F1F5F9';
    if (activation > 0.6) return '#94A3B8';
    if (activation > 0.4) return '#475569';
    return '#1E293B';
  },
  
  dragstarted(event, d) {
    if (!event.active) this.simulation.alphaTarget(0.3).restart();
    d.fx = d.x;
    d.fy = d.y;
  },
  
  dragged(event, d) {
    d.fx = event.x;
    d.fy = event.y;
  },
  
  dragended(event, d) {
    if (!event.active) this.simulation.alphaTarget(0);
    d.fx = null;
    d.fy = null;
  }
};

// Memory Usage Chart Hook
export const MemoryChart = {
  mounted() {
    this.initChart();
  },
  
  initChart() {
    const ctx = this.el.getContext('2d');
    const shortTerm = parseFloat(this.el.dataset.shortTerm || '0');
    const working = parseFloat(this.el.dataset.working || '0');
    const longTerm = parseFloat(this.el.dataset.longTerm || '0');
    
    this.chart = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Short-term', 'Working', 'Long-term'],
        datasets: [{
          data: [shortTerm, working, longTerm],
          backgroundColor: ['#3B82F6', '#60A5FA', '#93C5FD'],
          borderColor: ['#1E40AF', '#3B82F6', '#60A5FA'],
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: { color: '#9CA3AF', padding: 20 }
          }
        },
        animation: {
          animateRotate: true,
          duration: 1000
        }
      }
    });
  },
  
  destroyed() {
    if (this.chart) this.chart.destroy();
  }
};

// Pattern Confidence Heatmap Hook
export const PatternHeatmap = {
  mounted() {
    this.initHeatmap();
  },
  
  initHeatmap() {
    const patterns = JSON.parse(this.el.dataset.patterns || '[]');
    
    this.chart = echarts.init(this.el, 'dark');
    
    // Generate heatmap data
    const data = patterns.map((pattern, i) => [
      i % 20,
      Math.floor(i / 20),
      pattern.confidence
    ]);
    
    const option = {
      tooltip: {
        position: 'top',
        formatter: (params) => {
          return `Pattern ${params.data[0]},${params.data[1]}<br/>Confidence: ${params.data[2]}%`;
        }
      },
      grid: {
        height: '80%',
        top: '10%'
      },
      xAxis: {
        type: 'category',
        data: Array.from({length: 20}, (_, i) => i),
        splitArea: { show: true }
      },
      yAxis: {
        type: 'category',
        data: Array.from({length: 20}, (_, i) => i),
        splitArea: { show: true }
      },
      visualMap: {
        min: 0,
        max: 100,
        calculable: true,
        orient: 'horizontal',
        left: 'center',
        bottom: '5%',
        inRange: {
          color: ['#1E293B', '#475569', '#94A3B8', '#F1F5F9']
        }
      },
      series: [{
        name: 'Pattern Confidence',
        type: 'heatmap',
        data: data,
        label: {
          show: false
        },
        emphasis: {
          itemStyle: {
            shadowBlur: 10,
            shadowColor: 'rgba(0, 0, 0, 0.5)'
          }
        }
      }]
    };
    
    this.chart.setOption(option);
  },
  
  destroyed() {
    if (this.chart) this.chart.dispose();
  }
};

// CPU Gauge Hook
export const CPUGauge = {
  mounted() {
    this.initGauge();
    this.handleEvent("update_cpu", (data) => this.updateGauge(data.usage));
  },
  
  initGauge() {
    const ctx = this.el.getContext('2d');
    const usage = parseFloat(this.el.dataset.usage || '0');
    
    this.chart = new Chart(ctx, {
      type: 'doughnut',
      data: {
        datasets: [{
          data: [usage, 100 - usage],
          backgroundColor: ['#3B82F6', '#1E293B'],
          borderWidth: 0,
          cutout: '80%'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        rotation: -90,
        circumference: 180,
        plugins: {
          legend: { display: false },
          tooltip: { enabled: false }
        }
      },
      plugins: [{
        beforeDraw: (chart) => {
          const width = chart.width;
          const height = chart.height;
          const ctx = chart.ctx;
          
          ctx.restore();
          ctx.font = '24px Arial';
          ctx.textBaseline = 'middle';
          ctx.fillStyle = '#F1F5F9';
          
          const text = `${usage}%`;
          const textX = Math.round((width - ctx.measureText(text).width) / 2);
          const textY = height / 2 + 20;
          
          ctx.fillText(text, textX, textY);
          ctx.save();
        }
      }]
    });
  },
  
  updateGauge(newUsage) {
    if (this.chart) {
      this.chart.data.datasets[0].data = [newUsage, 100 - newUsage];
      this.chart.update('none');
    }
  },
  
  destroyed() {
    if (this.chart) this.chart.destroy();
  }
};

// Memory Gauge Hook (same as CPU but for memory)
export const MemoryGauge = {
  mounted() {
    this.initGauge();
    this.handleEvent("update_memory", (data) => this.updateGauge(data.usage));
  },
  
  initGauge() {
    const ctx = this.el.getContext('2d');
    const usage = parseFloat(this.el.dataset.usage || '0');
    
    this.chart = new Chart(ctx, {
      type: 'doughnut',
      data: {
        datasets: [{
          data: [usage, 100 - usage],
          backgroundColor: ['#60A5FA', '#1E293B'],
          borderWidth: 0,
          cutout: '80%'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        rotation: -90,
        circumference: 180,
        plugins: {
          legend: { display: false },
          tooltip: { enabled: false }
        }
      },
      plugins: [{
        beforeDraw: (chart) => {
          const width = chart.width;
          const height = chart.height;
          const ctx = chart.ctx;
          
          ctx.restore();
          ctx.font = '24px Arial';
          ctx.textBaseline = 'middle';
          ctx.fillStyle = '#F1F5F9';
          
          const text = `${usage}%`;
          const textX = Math.round((width - ctx.measureText(text).width) / 2);
          const textY = height / 2 + 20;
          
          ctx.fillText(text, textX, textY);
          ctx.save();
        }
      }]
    });
  },
  
  updateGauge(newUsage) {
    if (this.chart) {
      this.chart.data.datasets[0].data = [newUsage, 100 - newUsage];
      this.chart.update('none');
    }
  },
  
  destroyed() {
    if (this.chart) this.chart.destroy();
  }
};

// Network Chart Hook
export const NetworkChart = {
  mounted() {
    this.initChart();
    this.handleEvent("update_network", (data) => this.updateChart(data));
  },
  
  initChart() {
    const ctx = this.el.getContext('2d');
    const networkIn = parseFloat(this.el.dataset.in || '0');
    const networkOut = parseFloat(this.el.dataset.out || '0');
    
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: Array.from({length: 30}, (_, i) => i + 's'),
        datasets: [{
          label: 'Network In',
          data: Array.from({length: 30}, () => Math.random() * 5),
          borderColor: '#3B82F6',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          fill: false,
          tension: 0.4
        }, {
          label: 'Network Out',
          data: Array.from({length: 30}, () => Math.random() * 3),
          borderColor: '#60A5FA',
          backgroundColor: 'rgba(96, 165, 250, 0.1)',
          fill: false,
          tension: 0.4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            ticks: { color: '#9CA3AF' },
            grid: { color: 'rgba(156, 163, 175, 0.1)' }
          },
          x: {
            ticks: { color: '#9CA3AF' },
            grid: { color: 'rgba(156, 163, 175, 0.1)' }
          }
        },
        plugins: {
          legend: { labels: { color: '#9CA3AF' } }
        }
      }
    });
  },
  
  updateChart(data) {
    if (this.chart) {
      this.chart.data.datasets[0].data = data.in;
      this.chart.data.datasets[1].data = data.out;
      this.chart.update('none');
    }
  },
  
  destroyed() {
    if (this.chart) this.chart.destroy();
  }
};

// Neural Grid Canvas Hook for high-performance visualization
export const NeuralGridCanvas = {
  mounted() {
    this.initCanvas();
    this.handleEvent("update_neurons", (data) => this.updateNeurons(data));
  },
  
  initCanvas() {
    this.canvas = document.createElement('canvas');
    this.ctx = this.canvas.getContext('2d');
    this.el.appendChild(this.canvas);
    
    this.resizeCanvas();
    this.neurons = JSON.parse(this.el.dataset.neurons || '[]');
    this.zoom = parseFloat(this.el.dataset.zoom || '1');
    
    this.render();
    
    // Add mouse interaction
    this.canvas.addEventListener('mousemove', this.handleMouseMove.bind(this));
    this.canvas.addEventListener('click', this.handleClick.bind(this));
  },
  
  resizeCanvas() {
    this.canvas.width = this.el.offsetWidth;
    this.canvas.height = this.el.offsetHeight;
  },
  
  render() {
    const { width, height } = this.canvas;
    this.ctx.clearRect(0, 0, width, height);
    
    const gridSize = 100; // 100x100 grid for 10,000 neurons
    const cellSize = Math.min(width, height) / gridSize * this.zoom;
    
    this.neurons.forEach((neuron, index) => {
      const x = (index % gridSize) * cellSize;
      const y = Math.floor(index / gridSize) * cellSize;
      
      this.ctx.fillStyle = this.getNeuronColor(neuron.activation);
      this.ctx.fillRect(x, y, cellSize - 1, cellSize - 1);
      
      // Add glow effect for highly active neurons
      if (neuron.activation > 0.8) {
        this.ctx.shadowColor = '#60A5FA';
        this.ctx.shadowBlur = 4;
        this.ctx.fillRect(x, y, cellSize - 1, cellSize - 1);
        this.ctx.shadowBlur = 0;
      }
    });
  },
  
  getNeuronColor(activation) {
    if (activation > 0.8) return '#F1F5F9';
    if (activation > 0.6) return '#94A3B8';
    if (activation > 0.4) return '#475569';
    if (activation > 0.2) return '#374151';
    return '#1E293B';
  },
  
  handleMouseMove(event) {
    const rect = this.canvas.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;
    
    // Calculate which neuron is being hovered
    const gridSize = 100;
    const cellSize = Math.min(this.canvas.width, this.canvas.height) / gridSize * this.zoom;
    const neuronX = Math.floor(x / cellSize);
    const neuronY = Math.floor(y / cellSize);
    const neuronIndex = neuronY * gridSize + neuronX;
    
    if (neuronIndex < this.neurons.length) {
      const neuron = this.neurons[neuronIndex];
      this.pushEvent("neuron_hover", {
        id: neuron.id,
        activation: neuron.activation,
        x: neuronX,
        y: neuronY
      });
    }
  },
  
  handleClick(event) {
    const rect = this.canvas.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;
    
    const gridSize = 100;
    const cellSize = Math.min(this.canvas.width, this.canvas.height) / gridSize * this.zoom;
    const neuronX = Math.floor(x / cellSize);
    const neuronY = Math.floor(y / cellSize);
    const neuronIndex = neuronY * gridSize + neuronX;
    
    if (neuronIndex < this.neurons.length) {
      const neuron = this.neurons[neuronIndex];
      this.pushEvent("neuron_click", {
        id: neuron.id,
        activation: neuron.activation
      });
    }
  },
  
  updateNeurons(data) {
    this.neurons = data.neurons;
    this.zoom = data.zoom || this.zoom;
    this.render();
  }
};

// System Performance Chart Hook
export const SystemPerformanceChart = {
  mounted() {
    this.initChart();
    this.handleEvent("update_performance", (data) => this.updateChart(data));
  },
  
  initChart() {
    const ctx = this.el.getContext('2d');
    const cpu = parseFloat(this.el.dataset.cpu || '0');
    const memory = parseFloat(this.el.dataset.memory || '0');
    const disk = parseFloat(this.el.dataset.disk || '0');
    const network = parseFloat(this.el.dataset.network || '0');
    
    // Generate time series data
    const timeLabels = Array.from({length: 30}, (_, i) => {
      const time = new Date(Date.now() - (29 - i) * 2000);
      return time.toLocaleTimeString();
    });
    
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: timeLabels,
        datasets: [{
          label: 'CPU Usage (%)',
          data: Array.from({length: 30}, () => cpu + (Math.random() - 0.5) * 10),
          borderColor: '#3B82F6',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          fill: false,
          tension: 0.4
        }, {
          label: 'Memory Usage (MB)',
          data: Array.from({length: 30}, () => memory + (Math.random() - 0.5) * 20),
          borderColor: '#60A5FA',
          backgroundColor: 'rgba(96, 165, 250, 0.1)',
          fill: false,
          tension: 0.4
        }, {
          label: 'Network I/O (MB/s)',
          data: Array.from({length: 30}, () => network + (Math.random() - 0.5) * 2),
          borderColor: '#93C5FD',
          backgroundColor: 'rgba(147, 197, 253, 0.1)',
          fill: false,
          tension: 0.4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            ticks: { color: '#9CA3AF' },
            grid: { color: 'rgba(156, 163, 175, 0.1)' }
          },
          x: {
            ticks: { color: '#9CA3AF' },
            grid: { color: 'rgba(156, 163, 175, 0.1)' }
          }
        },
        plugins: {
          legend: { 
            labels: { color: '#9CA3AF' },
            position: 'top'
          }
        },
        animation: {
          duration: 200,
          easing: 'easeInOutQuart'
        }
      }
    });
  },
  
  updateChart(data) {
    if (this.chart) {
      // Add new data point and remove oldest
      this.chart.data.datasets[0].data.push(data.cpu);
      this.chart.data.datasets[1].data.push(data.memory);
      this.chart.data.datasets[2].data.push(data.network);
      
      this.chart.data.datasets.forEach(dataset => {
        if (dataset.data.length > 30) {
          dataset.data.shift();
        }
      });
      
      this.chart.update('none');
    }
  },
  
  destroyed() {
    if (this.chart) this.chart.destroy();
  }
};

// Consciousness Visualization Hook
export const ConsciousnessViz = {
  mounted() {
    this.initViz();
    this.handleEvent("update_consciousness", (data) => this.updateViz(data));
  },
  
  initViz() {
    const level = parseFloat(this.el.dataset.level || '0');
    const trinity = this.el.dataset.trinity === 'true';
    
    this.svg = d3.select(this.el)
      .append('svg')
      .attr('width', '100%')
      .attr('height', '100%');
    
    this.createCircles(level, trinity);
  },
  
  createCircles(level, trinity) {
    const width = this.el.offsetWidth;
    const height = this.el.offsetHeight;
    const centerX = width / 2;
    const centerY = height / 2;
    
    // Clear existing circles
    this.svg.selectAll('*').remove();
    
    // Create multiple consciousness rings
    const rings = trinity ? 3 : 1;
    
    for (let i = 0; i < rings; i++) {
      const radius = 80 - (i * 20);
      const strokeWidth = 8 - (i * 2);
      
      this.svg.append('circle')
        .attr('cx', centerX)
        .attr('cy', centerY)
        .attr('r', radius)
        .attr('fill', 'none')
        .attr('stroke', '#374151')
        .attr('stroke-width', strokeWidth);
      
      this.svg.append('circle')
        .attr('cx', centerX)
        .attr('cy', centerY)
        .attr('r', radius)
        .attr('fill', 'none')
        .attr('stroke', trinity ? '#60A5FA' : '#3B82F6')
        .attr('stroke-width', strokeWidth)
        .attr('stroke-dasharray', 2 * Math.PI * radius)
        .attr('stroke-dashoffset', 2 * Math.PI * radius * (1 - level))
        .attr('transform', `rotate(-90 ${centerX} ${centerY})`)
        .style('transition', 'stroke-dashoffset 1s ease');
    }
  },
  
  updateViz(data) {
    this.createCircles(data.level, data.trinity);
  }
};