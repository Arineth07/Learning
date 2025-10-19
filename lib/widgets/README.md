# Widgets Directory

This directory contains reusable UI components used across multiple screens.

## Purpose
Custom widgets promote code reuse, maintain consistent UI patterns, and follow the DRY (Don't Repeat Yourself) principle. These components can be composed to build complex interfaces.

## Planned Widgets

### QuestionCard (`question_card.dart`)
Displays a question with options:
- Question text display
- Multiple choice options
- Selection state
- Visual feedback
- Customizable styling

### ProgressIndicator (`progress_indicator.dart`)
Custom progress visualization:
- Circular progress with percentage
- Linear progress bars
- Animated transitions
- Color-coded by performance
- Label and subtitle support

### KnowledgeGapCard (`knowledge_gap_card.dart`)
Visualizes identified knowledge gaps:
- Gap description
- Severity indicator
- Related topics
- Action buttons
- Expandable details

### PerformanceChart (`performance_chart.dart`)
Charts for performance visualization (using fl_chart):
- Line charts for trends
- Bar charts for comparisons
- Pie charts for distributions
- Interactive tooltips
- Customizable colors and labels

### SubjectCard (`subject_card.dart`)
Subject overview card:
- Subject icon/image
- Subject name
- Progress indicator
- Quick stats
- Tap to navigate

### TopicListItem (`topic_list_item.dart`)
List item for topics:
- Topic name
- Completion status
- Difficulty indicator
- Question count
- Mastery level

### AnswerOption (`answer_option.dart`)
Individual answer choice widget:
- Option text
- Selection state
- Correct/incorrect indicator
- Tap handling
- Animation effects

### StatCard (`stat_card.dart`)
Displays a single statistic:
- Stat value (large text)
- Stat label
- Icon
- Trend indicator
- Color theming

### EmptyState (`empty_state.dart`)
Placeholder for empty content:
- Icon
- Message
- Optional action button
- Customizable styling

### LoadingOverlay (`loading_overlay.dart`)
Loading indicator overlay:
- Circular progress indicator
- Optional message
- Blocks interaction
- Dismissible option

### ErrorWidget (`error_widget.dart`)
Error state display:
- Error icon
- Error message
- Retry button
- Customizable actions

### ConfirmationDialog (`confirmation_dialog.dart`)
Reusable confirmation dialog:
- Title and message
- Confirm/cancel buttons
- Customizable actions
- Material Design styling

## Widget Structure

### Basic Template
```dart
class QuestionCard extends StatelessWidget {
  final Question question;
  final Function(String) onAnswerSelected;
  final String? selectedAnswer;

  const QuestionCard({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    this.selectedAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.text,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...question.options.map((option) => AnswerOption(
              text: option,
              isSelected: option == selectedAnswer,
              onTap: () => onAnswerSelected(option),
            )),
          ],
        ),
      ),
    );
  }
}
```

## Usage Example
```dart
// In a screen
QuestionCard(
  question: currentQuestion,
  selectedAnswer: selectedAnswer,
  onAnswerSelected: (answer) {
    setState(() {
      selectedAnswer = answer;
    });
  },
)
```

## Best Practices

### Design Principles
- Keep widgets small and focused
- Make widgets reusable and configurable
- Use composition over inheritance
- Follow Material Design guidelines
- Ensure accessibility

### Performance
- Use `const` constructors when possible
- Avoid unnecessary rebuilds
- Implement `shouldRebuild` for complex widgets
- Use `ListView.builder` for long lists

### Customization
- Provide sensible defaults
- Allow customization through parameters
- Support theming
- Document parameters clearly

### Testing
- Write widget tests
- Test different states
- Test user interactions
- Verify accessibility

## Naming Conventions
- Use descriptive names (e.g., `QuestionCard`, not `QCard`)
- Follow PascalCase for class names
- Use snake_case for file names
- Suffix with widget type when appropriate (e.g., `Card`, `Button`, `Dialog`)

## Organization
As the widgets directory grows, consider organizing into subdirectories:
- `widgets/cards/` - Card-style widgets
- `widgets/buttons/` - Custom buttons
- `widgets/charts/` - Chart components
- `widgets/dialogs/` - Dialog widgets
- `widgets/indicators/` - Progress and status indicators
