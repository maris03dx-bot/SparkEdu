import 'package:flutter/material.dart';

import 'event_request_screen.dart';
import 'approved_events_screen.dart';
import 'pending_events_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // --------------------------------------------------
        // CREATE EVENT
        // --------------------------------------------------

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.add_circle,
              color: Colors.purple,
            ),
            title: const Text(
              "Create Event Proposal",
            ),
            subtitle: const Text(
              "Send to Mentor",
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const EventRequestScreen(),
                ),
              );
            },
          ),
        ),

        // --------------------------------------------------
        // APPROVED EVENTS
        // --------------------------------------------------

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.event_available,
              color: Colors.green,
            ),
            title: const Text(
              "Approved Events",
            ),
            subtitle: const Text(
              "View approved events",
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ApprovedEventsScreen(),
                ),
              );
            },
          ),
        ),

        // --------------------------------------------------
        // PENDING EVENTS
        // --------------------------------------------------

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.pending_actions,
              color: Colors.orange,
            ),
            title: const Text(
              "Pending Approval",
            ),
            subtitle: const Text(
              "View pending event proposals",
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const PendingEventsScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}