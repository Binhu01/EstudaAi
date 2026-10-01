export function freeEntitlements() {
  return {
    plan: 'FREE' as const,
    capabilities: { advancedAi: false, generatedQuestions: false, advancedAnalytics: false },
  };
}
