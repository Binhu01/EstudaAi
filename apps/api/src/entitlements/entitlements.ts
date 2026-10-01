export function freeEntitlements(steveDailyMessages = 10) {
  return {
    plan: 'FREE' as const,
    capabilities: { steve:true, advancedAi: false, generatedQuestions: false, advancedAnalytics: false },
    limits: {steveDailyMessages},
  };
}
