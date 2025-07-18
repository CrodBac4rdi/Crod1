package main

import (
    "bytes"
    "encoding/json"
    "io"
    "log"
    "net/http"
    "os"
    "time"
)

type Message struct {
    Content string `json:"content"`
    Context string `json:"context"`
}

type CrodAnalysis struct {
    OriginalMessage string `json:"original_message"`
    CrodAnalysis    struct {
        Confidence       float64  `json:"confidence"`
        Mood            string   `json:"mood"`
        Intent          string   `json:"intent"`
        NeuronsActivated int      `json:"neurons_activated"`
    } `json:"crod_analysis"`
    Suggestions struct {
        Tone    string   `json:"tone"`
        FocusOn []string `json:"focus_on"`
        Avoid   []string `json:"avoid"`
    } `json:"suggestions"`
}

var crodURL = getEnv("CROD_URL", "http://localhost:4000/api/claude/process")

func main() {
    http.HandleFunc("/process", handleProcess)
    http.HandleFunc("/health", handleHealth)
    
    port := getEnv("PORT", "9090")
    log.Printf("🧠 Claude-CROD Bridge starting on port %s", port)
    log.Printf("📡 CROD endpoint: %s", crodURL)
    
    log.Fatal(http.ListenAndServe(":"+port, nil))
}

func handleProcess(w http.ResponseWriter, r *http.Request) {
    if r.Method != "POST" {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }

    var msg Message
    if err := json.NewDecoder(r.Body).Decode(&msg); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    // Send to CROD for analysis
    analysis, err := analyzeWithCROD(msg)
    if err != nil {
        log.Printf("❌ CROD analysis failed: %v", err)
        // Return original message if CROD fails
        json.NewEncoder(w).Encode(map[string]interface{}{
            "content": msg.Content,
            "crod_available": false,
            "error": err.Error(),
        })
        return
    }

    // Log what CROD found
    log.Printf("✅ CROD Analysis: mood=%s, intent=%s, confidence=%.2f", 
        analysis.CrodAnalysis.Mood,
        analysis.CrodAnalysis.Intent,
        analysis.CrodAnalysis.Confidence)

    // Return enhanced message with CROD insights
    response := map[string]interface{}{
        "content": msg.Content,
        "crod_enhanced": true,
        "analysis": analysis,
        "timestamp": time.Now().Unix(),
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}

func analyzeWithCROD(msg Message) (*CrodAnalysis, error) {
    payload := map[string]string{
        "message": msg.Content,
        "context": msg.Context,
    }
    
    jsonData, err := json.Marshal(payload)
    if err != nil {
        return nil, err
    }

    resp, err := http.Post(crodURL, "application/json", bytes.NewBuffer(jsonData))
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    body, err := io.ReadAll(resp.Body)
    if err != nil {
        return nil, err
    }

    var analysis CrodAnalysis
    if err := json.Unmarshal(body, &analysis); err != nil {
        return nil, err
    }

    return &analysis, nil
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]string{
        "status": "healthy",
        "service": "claude-crod-bridge",
    })
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}