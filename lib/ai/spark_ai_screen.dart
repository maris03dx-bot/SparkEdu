import 'package:flutter/material.dart';

import 'academic_dashboard_screen.dart';
import 'chat_screen.dart';
import 'study_assistant_screen.dart';
import 'quiz_generator_screen.dart';
import 'exam_prep_screen.dart';
import 'flashcard_screen.dart';
import 'document_chat_screen.dart';
import 'study_planner_screen.dart';

class SparkAIScreen extends StatelessWidget {
  const SparkAIScreen({super.key});

  // ============================================================
  // OPEN SCREEN
  // ============================================================

  void _openScreen(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  // ============================================================
  // COMING SOON
  // ============================================================

  void _showComingSoon(
    BuildContext context,
    String title,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title is coming soon...',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // QUICK ACTION
  // ============================================================

  Widget _buildQuickAction({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25222B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STUDY TOOL
  // ============================================================

  Widget _buildStudyTool({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF25222B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF24212A),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FA),

      // ==========================================================
      // NO APP BAR
      //
      // StudentNavigation already provides the SparkAI title.
      // ==========================================================

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width =
                constraints.maxWidth;

            final double horizontalPadding =
                width < 360 ? 12 : 16;

            return SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                28,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // SPARKAI HERO
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6B4FD3),
                          Color(0xFF8B6DE3),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B4FD3)
                              .withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -18,
                          top: -18,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration:
                                BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white
                                  .withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 25,
                          bottom: -35,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration:
                                BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white
                                  .withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration:
                                      BoxDecoration(
                                    color: Colors.white
                                        .withValues(
                                      alpha: 0.16,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 27,
                                  ),
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                const Expanded(
                                  child: Text(
                                    'SparkAI',
                                    style: TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize: 24,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              'Your Personal Learning Assistant',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 7),

                            Text(
                              'Ask questions, understand difficult topics, '
                              'prepare for exams, and learn smarter with AI.',
                              style: TextStyle(
                                color: Colors.white
                                    .withValues(
                                  alpha: 0.88,
                                ),
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),

                            const SizedBox(height: 18),

                            // MAIN ASK DOUBT BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _openScreen(
                                    context,
                                    const ChatScreen(),
                                  );
                                },
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Ask SparkAI',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      Colors.white,
                                  foregroundColor:
                                      const Color(
                                    0xFF6B4FD3,
                                  ),
                                  elevation: 0,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // QUICK ACTIONS
                  // ==================================================

                  _buildSectionTitle(
                    title: 'Quick Actions',
                    subtitle:
                        'Start learning with one tap',
                  ),

                  const SizedBox(height: 12),

                  _buildQuickAction(
                    context: context,
                    title: 'Ask Doubt',
                    subtitle:
                        'Get instant answers from SparkAI',
                    icon: Icons.chat_rounded,
                    color: Colors.blue,
                    onTap: () {
                      _openScreen(
                        context,
                        const ChatScreen(),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildQuickAction(
                    context: context,
                    title: 'Summarize Notes',
                    subtitle:
                        'Turn long notes into simple points',
                    icon: Icons.summarize_rounded,
                    color: Colors.green,
                    onTap: () {
                      _openScreen(
                        context,
                        const StudyAssistantScreen(),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildQuickAction(
                    context: context,
                    title: 'Generate Quiz',
                    subtitle:
                        'Create MCQs for practice',
                    icon: Icons.quiz_rounded,
                    color: Colors.orange,
                    onTap: () {
                      _openScreen(
                        context,
                        const QuizGeneratorScreen(),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildQuickAction(
                    context: context,
                    title: 'Exam Preparation',
                    subtitle:
                        'Prepare smarter for your exams',
                    icon: Icons.school_rounded,
                    color: Colors.deepOrange,
                    onTap: () {
                      _openScreen(
                        context,
                        const ExamPrepScreen(),
                      );
                    },
                  ),

                  const SizedBox(height: 26),

                  // ==================================================
                  // STUDY TOOLS
                  // ==================================================

                  _buildSectionTitle(
                    title: 'Study Tools',
                    subtitle:
                        'Everything you need for smarter learning',
                  ),

                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio:
                        width < 360 ? 1.05 : 1.12,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStudyTool(
                        context: context,
                        title: 'Academic Dashboard',
                        subtitle:
                            'View AI academic insights',
                        icon:
                            Icons.dashboard_customize_rounded,
                        color: Colors.deepPurple,
                        onTap: () {
                          _openScreen(
                            context,
                            const AcademicDashboardScreen(),
                          );
                        },
                      ),

                      _buildStudyTool(
                        context: context,
                        title: 'Document Chat',
                        subtitle:
                            'Chat with PDF, image & notes',
                        icon:
                            Icons.description_rounded,
                        color: Colors.blueAccent,
                        onTap: () {
                          _openScreen(
                            context,
                            const DocumentChatScreen(),
                          );
                        },
                      ),

                      _buildStudyTool(
                        context: context,
                        title: 'Study Planner',
                        subtitle:
                            'Create a smart study schedule',
                        icon:
                            Icons.calendar_month_rounded,
                        color: Colors.teal,
                        onTap: () {
                          _openScreen(
                            context,
                            const StudyPlannerScreen(),
                          );
                        },
                      ),

                      _buildStudyTool(
                        context: context,
                        title: 'Flashcards',
                        subtitle:
                            'Generate AI-powered flashcards',
                        icon: Icons.style_rounded,
                        color: Colors.amber.shade700,
                        onTap: () {
                          _openScreen(
                            context,
                            const FlashcardScreen(),
                          );
                        },
                      ),

                      _buildStudyTool(
                        context: context,
                        title: 'Coding Assistant',
                        subtitle:
                            'Get help fixing coding errors',
                        icon: Icons.code_rounded,
                        color: Colors.indigo,
                        onTap: () {
                          _showComingSoon(
                            context,
                            'Coding Assistant',
                          );
                        },
                      ),

                      _buildStudyTool(
                        context: context,
                        title: 'Career Guidance',
                        subtitle:
                            'Explore career possibilities',
                        icon: Icons.work_outline_rounded,
                        color: Colors.redAccent,
                        onTap: () {
                          _showComingSoon(
                            context,
                            'Career Guidance',
                          );
                        },
                      ),

                      _buildStudyTool(
                        context: context,
                        title: 'Performance Analysis',
                        subtitle:
                            'Understand your learning progress',
                        icon: Icons.analytics_rounded,
                        color: Colors.indigoAccent,
                        onTap: () {
                          _showComingSoon(
                            context,
                            'Performance Analysis',
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // ==================================================
                  // AI LEARNING TIPS
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE9E4F2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4FD3)
                                .withValues(alpha: 0.10),
                            borderRadius:
                                BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Color(0xFF6B4FD3),
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Learn Smarter with SparkAI',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      Color(0xFF29252F),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Ask follow-up questions, request simple '
                                'explanations, and use examples to understand '
                                'difficult concepts better.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // FOOTER
                  // ==================================================

                  Center(
                    child: Text(
                      'LEARN • GROW • INSPIRE',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10.5,
                        fontWeight:
                            FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}