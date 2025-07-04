import { createContext, useContext, ReactNode } from 'react';
import { useOnboarding } from '@/hooks/useOnboarding';
import OnboardingTutorial from './OnboardingTutorial';

interface TutorialContextType {
  startTutorial: () => void;
  hasCompletedTutorial: boolean;
  isFirstTimeUser: boolean;
  isLoading: boolean;
}

const TutorialContext = createContext<TutorialContextType | undefined>(undefined);

export function useTutorial() {
  const context = useContext(TutorialContext);
  if (context === undefined) {
    throw new Error('useTutorial must be used within a TutorialProvider');
  }
  return context;
}

interface TutorialProviderProps {
  children: ReactNode;
}

export function TutorialProvider({ children }: TutorialProviderProps) {
  const {
    shouldShowTutorial,
    isFirstTimeUser,
    hasCompletedTutorial,
    isLoading,
    startTutorial,
    completeTutorial,
    skipTutorial
  } = useOnboarding();

  return (
    <TutorialContext.Provider
      value={{
        startTutorial,
        hasCompletedTutorial,
        isFirstTimeUser,
        isLoading
      }}
    >
      {children}
      
      {!isLoading && (
        <OnboardingTutorial
          isOpen={shouldShowTutorial}
          onClose={skipTutorial}
          onComplete={completeTutorial}
        />
      )}
    </TutorialContext.Provider>
  );
}