/**
 * Performance Monitoring & Logging for Daily Briefing System
 * Tracks generation latency, AI quality, and error rates
 * 
 * Usage:
 *   await BriefingPerformanceMonitor.logGenerationStart("user-id-123")
 *   // ... briefing generation ...
 *   await BriefingPerformanceMonitor.logGenerationComplete("user-id-123", briefing)
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin (must be called in Cloud Function setup)
const initializePerformanceMonitoring = () => {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
};

class BriefingPerformanceMetrics {
  /**
   * Log generation start time and user info
   */
  static async logGenerationStart(userId) {
    initializePerformanceMonitoring();
    const db = admin.firestore();
    const timestamp = Date.now();
    
    try {
      await db.collection('briefing_metrics').add({
        userId,
        event: 'generation_start',
        timestamp,
        startTime: new Date().toISOString(),
      });
      console.log(`[PERF] Briefing generation started for user ${userId}`);
    } catch (error) {
      console.error('[PERF ERROR] Failed to log generation start:', error);
    }
  }

  /**
   * Log successful generation completion with quality metrics
   */
  static async logGenerationComplete(userId, briefing) {
    initializePerformanceMonitoring();
    const db = admin.firestore();
    const timestamp = Date.now();
    
    try {
      const metrics = {
        userId,
        event: 'generation_complete',
        timestamp,
        completedAt: new Date().toISOString(),
        
        // Briefing quality metrics
        headlineLength: briefing.headline?.length || 0,
        correlationCardCount: briefing.correlationCards?.length || 0,
        hasNudge: !!briefing.nudge,
        hasWeeklyTrend: !!briefing.weeklyTrend,
        averageCorrelationConfidence: 
          briefing.correlationCards?.length > 0
            ? (briefing.correlationCards.reduce((sum, c) => sum + (c.confidence || 0), 0) / 
               briefing.correlationCards.length)
            : 0,
        
        // Data availability
        dataQuality: this._assessDataQuality(briefing),
      };
      
      await db.collection('briefing_metrics').add(metrics);
      console.log(`[PERF] Briefing generation completed for user ${userId}`, {
        cards: metrics.correlationCardCount,
        confidence: metrics.averageCorrelationConfidence.toFixed(2),
      });
    } catch (error) {
      console.error('[PERF ERROR] Failed to log generation complete:', error);
    }
  }

  /**
   * Log API call latency (Gemini response time)
   */
  static async logAPILatency(userId, durationMs, modelUsed) {
    initializePerformanceMonitoring();
    const db = admin.firestore();
    
    try {
      await db.collection('briefing_metrics').add({
        userId,
        event: 'api_latency',
        timestamp: Date.now(),
        durationMs,
        modelUsed, // e.g., "gemini-2.5-flash"
        recordedAt: new Date().toISOString(),
      });
      
      if (durationMs > 10000) {
        console.warn(`[PERF WARN] Slow Gemini API response: ${durationMs}ms`);
      } else {
        console.log(`[PERF] Gemini API latency: ${durationMs}ms`);
      }
    } catch (error) {
      console.error('[PERF ERROR] Failed to log API latency:', error);
    }
  }

  /**
   * Log generation error with details
   */
  static async logGenerationError(userId, errorMessage, fallbackUsed) {
    initializePerformanceMonitoring();
    const db = admin.firestore();
    
    try {
      await db.collection('briefing_metrics').add({
        userId,
        event: 'generation_error',
        timestamp: Date.now(),
        errorMessage,
        fallbackUsed, // true if local pattern analyzer was used
        recordedAt: new Date().toISOString(),
      });
      console.error(`[PERF ERROR] Briefing generation failed for user ${userId}:`, errorMessage);
    } catch (error) {
      console.error('[PERF ERROR] Failed to log generation error:', error);
    }
  }

  /**
   * Assess overall data quality for briefing
   * Returns: 'excellent' | 'good' | 'adequate' | 'sparse'
   */
  static _assessDataQuality(briefing) {
    const cardCount = briefing.correlationCards?.length || 0;
    const avgConfidence = briefing.correlationCards?.length > 0
      ? briefing.correlationCards.reduce((sum, c) => sum + (c.confidence || 0), 0) / 
        briefing.correlationCards.length
      : 0;

    if (cardCount >= 3 && avgConfidence >= 0.75) {
      return 'excellent';
    } else if (cardCount >= 2 && avgConfidence >= 0.65) {
      return 'good';
    } else if (cardCount >= 1 && avgConfidence >= 0.55) {
      return 'adequate';
    } else {
      return 'sparse';
    }
  }

  /**
   * Fetch performance metrics for analysis (last N days)
   */
  static async getMetricsForAnalysis(daysBack = 7) {
    initializePerformanceMonitoring();
    const db = admin.firestore();
    
    try {
      const sinceTime = Date.now() - (daysBack * 24 * 60 * 60 * 1000);
      const snapshot = await db.collection('briefing_metrics')
        .where('timestamp', '>=', sinceTime)
        .orderBy('timestamp', 'desc')
        .limit(1000)
        .get();
      
      const metrics = {
        totalEvents: snapshot.docs.length,
        generationStarts: 0,
        generationCompletes: 0,
        generationErrors: 0,
        apiLatencies: [],
        averageCorrelationConfidence: 0,
        dataQualityDistribution: {
          excellent: 0,
          good: 0,
          adequate: 0,
          sparse: 0,
        },
        uniqueUsers: new Set(),
      };

      let totalConfidence = 0;
      let confidenceCount = 0;

      snapshot.forEach(doc => {
        const data = doc.data();
        metrics.uniqueUsers.add(data.userId);

        switch (data.event) {
          case 'generation_start':
            metrics.generationStarts++;
            break;
          case 'generation_complete':
            metrics.generationCompletes++;
            if (data.averageCorrelationConfidence) {
              totalConfidence += data.averageCorrelationConfidence;
              confidenceCount++;
            }
            if (data.dataQuality) {
              metrics.dataQualityDistribution[data.dataQuality]++;
            }
            break;
          case 'generation_error':
            metrics.generationErrors++;
            break;
          case 'api_latency':
            metrics.apiLatencies.push(data.durationMs);
            break;
        }
      });

      metrics.averageCorrelationConfidence = confidenceCount > 0 
        ? totalConfidence / confidenceCount 
        : 0;
      
      metrics.uniqueUsers = metrics.uniqueUsers.size;

      // Calculate API latency stats
      if (metrics.apiLatencies.length > 0) {
        metrics.apiLatencies.sort((a, b) => a - b);
        metrics.apiLatencyStats = {
          count: metrics.apiLatencies.length,
          min: metrics.apiLatencies[0],
          max: metrics.apiLatencies[metrics.apiLatencies.length - 1],
          median: metrics.apiLatencies[Math.floor(metrics.apiLatencies.length / 2)],
          p95: metrics.apiLatencies[Math.floor(metrics.apiLatencies.length * 0.95)],
          average: metrics.apiLatencies.reduce((a, b) => a + b, 0) / metrics.apiLatencies.length,
        };
      }

      // Calculate success rate
      metrics.successRate = metrics.generationStarts > 0
        ? ((metrics.generationCompletes / metrics.generationStarts) * 100).toFixed(2) + '%'
        : 'N/A';

      return metrics;
    } catch (error) {
      console.error('[PERF ERROR] Failed to fetch metrics:', error);
      return null;
    }
  }
}

module.exports = BriefingPerformanceMetrics;
