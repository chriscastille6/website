// Shared Assessment Runner Components
// Location: /static/assessments/shared/assessment-runner.js
// Purpose: Reusable React components for running assessments with consistent UI/UX
// Why: Provides standardized question types, progress tracking, and result display
// RELEVANT FILES: static/assessments/shared/supabase-client.js, static/assessments/*/index.html

// Ensure React and AssessmentLibrary are available
if (typeof React === 'undefined' || typeof window.AssessmentLibrary === 'undefined') {
    throw new Error('Assessment Runner requires React and AssessmentLibrary to be loaded first');
}

const { useState, useEffect, useCallback } = React;
const { AssessmentData, AssessmentUtils, AssessmentError } = window.AssessmentLibrary;

// Progress Bar Component
const ProgressBar = ({ current, total, label = null }) => {
    const percentage = Math.round((current / total) * 100);
    
    return (
        <div className="progress-container mb-6">
            <div className="flex justify-between items-center mb-2">
                <span className="text-sm font-medium text-gray-700">
                    {label || 'Progress'}
                </span>
                <span className="text-sm text-gray-500">
                    {current} of {total} ({percentage}%)
                </span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2">
                <div 
                    className="bg-blue-600 h-2 rounded-full transition-all duration-300 ease-out"
                    style={{ width: `${percentage}%` }}
                ></div>
            </div>
        </div>
    );
};

// Multiple Choice Question Component
const MultipleChoiceQuestion = ({ question, onAnswer, selectedAnswer = null }) => {
    const [selected, setSelected] = useState(selectedAnswer);
    const [startTime] = useState(Date.now());

    const handleSelect = (optionIndex) => {
        setSelected(optionIndex);
        const responseTime = Date.now() - startTime;
        
        onAnswer({
            selected: optionIndex,
            response_time: responseTime
        });
    };

    return (
        <div className="question-container">
            <h3 className="text-lg font-semibold mb-4 text-gray-900">
                {question.text}
            </h3>
            
            {question.description && (
                <p className="text-gray-600 mb-4">{question.description}</p>
            )}
            
            <div className="options-container space-y-3">
                {question.options.map((option, index) => (
                    <button
                        key={index}
                        onClick={() => handleSelect(index)}
                        className={`w-full text-left p-4 rounded-lg border-2 transition-all duration-200 ${
                            selected === index
                                ? 'border-blue-500 bg-blue-50 text-blue-900'
                                : 'border-gray-200 bg-white hover:border-gray-300 hover:bg-gray-50'
                        }`}
                    >
                        <div className="flex items-start">
                            <div className={`w-5 h-5 rounded-full border-2 mr-3 mt-0.5 flex-shrink-0 ${
                                selected === index
                                    ? 'border-blue-500 bg-blue-500'
                                    : 'border-gray-300'
                            }`}>
                                {selected === index && (
                                    <div className="w-full h-full rounded-full bg-white scale-50"></div>
                                )}
                            </div>
                            <div>
                                <div className="font-medium">{option.text}</div>
                                {option.description && (
                                    <div className="text-sm text-gray-500 mt-1">
                                        {option.description}
                                    </div>
                                )}
                            </div>
                        </div>
                    </button>
                ))}
            </div>
        </div>
    );
};

// Multiple Answer Question Component
const MultipleAnswerQuestion = ({ question, onAnswer, selectedAnswers = [] }) => {
    const [selected, setSelected] = useState(new Set(selectedAnswers));
    const [startTime] = useState(Date.now());

    const handleToggle = (optionIndex) => {
        const newSelected = new Set(selected);
        if (newSelected.has(optionIndex)) {
            newSelected.delete(optionIndex);
        } else {
            newSelected.add(optionIndex);
        }
        
        setSelected(newSelected);
        const responseTime = Date.now() - startTime;
        
        onAnswer({
            selected: Array.from(newSelected),
            response_time: responseTime
        });
    };

    return (
        <div className="question-container">
            <h3 className="text-lg font-semibold mb-4 text-gray-900">
                {question.text}
            </h3>
            
            {question.description && (
                <p className="text-gray-600 mb-4">{question.description}</p>
            )}
            
            <p className="text-sm text-gray-500 mb-4">
                Select all that apply:
            </p>
            
            <div className="options-container space-y-3">
                {question.options.map((option, index) => (
                    <button
                        key={index}
                        onClick={() => handleToggle(index)}
                        className={`w-full text-left p-4 rounded-lg border-2 transition-all duration-200 ${
                            selected.has(index)
                                ? 'border-blue-500 bg-blue-50 text-blue-900'
                                : 'border-gray-200 bg-white hover:border-gray-300 hover:bg-gray-50'
                        }`}
                    >
                        <div className="flex items-start">
                            <div className={`w-5 h-5 rounded border-2 mr-3 mt-0.5 flex-shrink-0 ${
                                selected.has(index)
                                    ? 'border-blue-500 bg-blue-500'
                                    : 'border-gray-300'
                            }`}>
                                {selected.has(index) && (
                                    <svg className="w-3 h-3 text-white m-0.5" fill="currentColor" viewBox="0 0 20 20">
                                        <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                                    </svg>
                                )}
                            </div>
                            <div>
                                <div className="font-medium">{option.text}</div>
                                {option.description && (
                                    <div className="text-sm text-gray-500 mt-1">
                                        {option.description}
                                    </div>
                                )}
                            </div>
                        </div>
                    </button>
                ))}
            </div>
        </div>
    );
};

// Likert Scale Question Component
const LikertScaleQuestion = ({ question, onAnswer, selectedValue = null }) => {
    const [selected, setSelected] = useState(selectedValue);
    const [startTime] = useState(Date.now());

    const scale = question.scale || {
        min: 1,
        max: 7,
        labels: {
            1: 'Strongly Disagree',
            4: 'Neutral',
            7: 'Strongly Agree'
        }
    };

    const handleSelect = (value) => {
        setSelected(value);
        const responseTime = Date.now() - startTime;
        
        onAnswer({
            value: value,
            response_time: responseTime
        });
    };

    const scalePoints = [];
    for (let i = scale.min; i <= scale.max; i++) {
        scalePoints.push(i);
    }

    return (
        <div className="question-container">
            <h3 className="text-lg font-semibold mb-4 text-gray-900">
                {question.text}
            </h3>
            
            {question.description && (
                <p className="text-gray-600 mb-6">{question.description}</p>
            )}
            
            <div className="likert-scale">
                <div className="flex justify-between items-center mb-4">
                    {scalePoints.map(point => (
                        <button
                            key={point}
                            onClick={() => handleSelect(point)}
                            className={`w-12 h-12 rounded-full border-2 font-semibold transition-all duration-200 ${
                                selected === point
                                    ? 'border-blue-500 bg-blue-500 text-white'
                                    : 'border-gray-300 bg-white hover:border-blue-300 hover:bg-blue-50'
                            }`}
                        >
                            {point}
                        </button>
                    ))}
                </div>
                
                <div className="flex justify-between text-sm text-gray-600">
                    {scalePoints.map(point => (
                        <div key={point} className="text-center w-12">
                            {scale.labels[point] && (
                                <div className="font-medium">{scale.labels[point]}</div>
                            )}
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};

// Conjoint Choice Task Component
const ConjointChoiceTask = ({ task, onChoice, attributes }) => {
    const [startTime] = useState(Date.now());

    const handleChoice = (alternativeIndex) => {
        const responseTime = Date.now() - startTime;
        
        onChoice({
            chosen_alternative: alternativeIndex,
            task_data: task,
            response_time: responseTime
        });
    };

    const formatAttributeValue = (attribute, value) => {
        if (attribute.formatter) {
            return attribute.formatter(value);
        }
        return value;
    };

    return (
        <div className="conjoint-task-container">
            <h3 className="text-lg font-semibold mb-6 text-gray-900 text-center">
                {task.instructions || 'Choose your preferred option:'}
            </h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {task.alternatives.map((alternative, altIndex) => (
                    <div key={altIndex} className="alternative-card">
                        <div className="bg-white border-2 border-gray-200 rounded-lg p-6 hover:border-blue-300 transition-colors duration-200">
                            <h4 className="text-lg font-semibold mb-4 text-center text-gray-800">
                                Option {String.fromCharCode(65 + altIndex)}
                            </h4>
                            
                            <div className="space-y-3 mb-6">
                                {attributes.map(attr => (
                                    <div key={attr.name} className="flex justify-between items-center">
                                        <span className="font-medium text-gray-700">
                                            {attr.label}:
                                        </span>
                                        <span className="text-gray-900">
                                            {formatAttributeValue(attr, alternative[attr.name])}
                                        </span>
                                    </div>
                                ))}
                            </div>
                            
                            <button
                                onClick={() => handleChoice(altIndex)}
                                className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-4 rounded-md transition-colors duration-200"
                            >
                                Choose Option {String.fromCharCode(65 + altIndex)}
                            </button>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
};

// Question Feedback Component
const QuestionFeedback = ({ feedback, isCorrect = null }) => {
    if (!feedback) return null;

    return (
        <div className={`feedback-container mt-4 p-4 rounded-lg border-l-4 ${
            isCorrect === true ? 'bg-green-50 border-green-400' :
            isCorrect === false ? 'bg-red-50 border-red-400' :
            'bg-blue-50 border-blue-400'
        }`}>
            <div className="flex items-start">
                <div className="flex-shrink-0 mr-3 mt-0.5">
                    {isCorrect === true && (
                        <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                        </svg>
                    )}
                    {isCorrect === false && (
                        <svg className="w-5 h-5 text-red-500" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                        </svg>
                    )}
                    {isCorrect === null && (
                        <svg className="w-5 h-5 text-blue-500" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                        </svg>
                    )}
                </div>
                <div className="flex-1">
                    <div className="text-sm text-gray-800" dangerouslySetInnerHTML={{ __html: feedback }} />
                </div>
            </div>
        </div>
    );
};

// Main Assessment Runner Component
const AssessmentRunner = ({ 
    assessmentName, 
    questions, 
    onComplete, 
    showProgress = true,
    allowBack = false,
    showFeedback = true 
}) => {
    const [currentQuestion, setCurrentQuestion] = useState(0);
    const [responses, setResponses] = useState({});
    const [assessmentData, setAssessmentData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [showQuestionFeedback, setShowQuestionFeedback] = useState(false);

    useEffect(() => {
        initializeAssessment();
    }, []);

    const initializeAssessment = async () => {
        try {
            const data = new AssessmentData(assessmentName);
            await data.initialize();
            setAssessmentData(data);
        } catch (err) {
            setError(AssessmentError.handle(err, 'initialization'));
        } finally {
            setLoading(false);
        }
    };

    const handleAnswer = async (questionId, questionType, responseData) => {
        if (!assessmentData) return;

        try {
            // Save to database
            await assessmentData.saveResponse(
                questionId,
                questionType,
                responseData,
                responseData.response_time
            );

            // Update local state
            setResponses(prev => ({
                ...prev,
                [questionId]: responseData
            }));

            // Show feedback if enabled
            if (showFeedback && questions[currentQuestion].feedback) {
                setShowQuestionFeedback(true);
                setTimeout(() => {
                    setShowQuestionFeedback(false);
                    nextQuestion();
                }, 3000);
            } else {
                nextQuestion();
            }
        } catch (err) {
            setError(AssessmentError.handle(err, 'saving response'));
        }
    };

    const nextQuestion = () => {
        if (currentQuestion < questions.length - 1) {
            setCurrentQuestion(prev => prev + 1);
        } else {
            completeAssessment();
        }
    };

    const prevQuestion = () => {
        if (allowBack && currentQuestion > 0) {
            setCurrentQuestion(prev => prev - 1);
        }
    };

    const completeAssessment = async () => {
        if (!assessmentData) return;

        try {
            // Calculate scores (this would be assessment-specific)
            const scores = calculateScores(responses, questions);
            
            // Save results
            await assessmentData.saveResult(scores);
            
            // Call completion handler
            onComplete(scores, responses);
        } catch (err) {
            setError(AssessmentError.handle(err, 'completing assessment'));
        }
    };

    const calculateScores = (responses, questions) => {
        // This is a basic implementation - each assessment would override this
        const totalQuestions = questions.length;
        const answeredQuestions = Object.keys(responses).length;
        
        return {
            completion_rate: (answeredQuestions / totalQuestions) * 100,
            total_questions: totalQuestions,
            answered_questions: answeredQuestions,
            responses: responses
        };
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-64">
                <div className="text-center">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
                    <p className="text-gray-600">Loading assessment...</p>
                </div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="text-center py-8">
                <div className="text-red-600 text-xl mb-4">⚠️</div>
                <p className="text-gray-600 mb-4">{error.user}</p>
                <button 
                    onClick={initializeAssessment}
                    className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md"
                >
                    Try Again
                </button>
            </div>
        );
    }

    const question = questions[currentQuestion];
    const questionId = AssessmentUtils.generateQuestionId(assessmentName, currentQuestion);

    return (
        <div className="assessment-runner max-w-4xl mx-auto p-6">
            {showProgress && (
                <ProgressBar 
                    current={currentQuestion + 1} 
                    total={questions.length}
                    label="Assessment Progress"
                />
            )}

            <div className="question-wrapper bg-white rounded-lg shadow-sm border border-gray-200 p-6">
                {question.type === 'mcq' && (
                    <MultipleChoiceQuestion
                        question={question}
                        onAnswer={(responseData) => handleAnswer(questionId, 'mcq', responseData)}
                        selectedAnswer={responses[questionId]?.selected}
                    />
                )}

                {question.type === 'multiple_answer' && (
                    <MultipleAnswerQuestion
                        question={question}
                        onAnswer={(responseData) => handleAnswer(questionId, 'multiple_answer', responseData)}
                        selectedAnswers={responses[questionId]?.selected || []}
                    />
                )}

                {question.type === 'likert' && (
                    <LikertScaleQuestion
                        question={question}
                        onAnswer={(responseData) => handleAnswer(questionId, 'likert', responseData)}
                        selectedValue={responses[questionId]?.value}
                    />
                )}

                {question.type === 'conjoint_choice' && (
                    <ConjointChoiceTask
                        task={question}
                        onChoice={(responseData) => handleAnswer(questionId, 'conjoint_choice', responseData)}
                        attributes={question.attributes}
                    />
                )}

                {showQuestionFeedback && question.feedback && (
                    <QuestionFeedback 
                        feedback={question.feedback}
                        isCorrect={question.correct_answer !== undefined ? 
                            responses[questionId]?.selected === question.correct_answer : null}
                    />
                )}
            </div>

            {allowBack && (
                <div className="flex justify-between mt-6">
                    <button
                        onClick={prevQuestion}
                        disabled={currentQuestion === 0}
                        className="bg-gray-300 hover:bg-gray-400 disabled:bg-gray-200 disabled:cursor-not-allowed text-gray-700 px-4 py-2 rounded-md"
                    >
                        Previous
                    </button>
                    <div></div>
                </div>
            )}
        </div>
    );
};

// Export components
window.AssessmentRunner = {
    AssessmentRunner,
    ProgressBar,
    MultipleChoiceQuestion,
    MultipleAnswerQuestion,
    LikertScaleQuestion,
    ConjointChoiceTask,
    QuestionFeedback
};
