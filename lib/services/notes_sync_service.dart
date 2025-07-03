import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';

class NotesSyncService {
  final supabase = Supabase.instance.client;

  // Push une note locale vers Supabase (insert ou update)
  Future<void> pushNote(Note note, String userId) async {
    if (note.remoteId == null) {
      // Nouvelle note : insert
      final response = await supabase.from('notes').insert(note.toSupabaseMap(userId)).select().single();
      note.remoteId = response['id'] as String?;
      note.syncStatus = SyncStatus.synced;
      note.lastSyncedAt = DateTime.tryParse(response['updated_at'] ?? '');
    } else {
      // Note existante : update
      final response = await supabase.from('notes').update(note.toSupabaseMap(userId)).eq('id', note.remoteId!).select().single();
      note.syncStatus = SyncStatus.synced;
      note.lastSyncedAt = DateTime.tryParse(response['updated_at'] ?? '');
    }
  }

  // Pull toutes les notes du cloud pour l'utilisateur
  Future<List<Note>> pullNotes(String userId) async {
    final response = await supabase.from('notes').select().eq('user_id', userId).eq('deleted', false);
    return (response as List).map((map) => Note.fromSupabase(map)).toList();
  }

  // Résoudre un conflit (choix local ou distant)
  Future<void> resolveConflict(Note local, Note remote, bool keepLocal, String userId) async {
    if (keepLocal) {
      await pushNote(local, userId);
    } else {
      // Remplacer local par distant (à gérer dans NotesProvider)
      // Ici, on ne fait rien côté cloud
    }
  }

  // S'abonner aux changements temps réel
  void subscribeToRealtime(String userId, void Function(Note) onRemoteChange) {
    supabase.channel('public:notes')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notes',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
        callback: (payload) {
          if (payload.newRecord != null) {
            final note = Note.fromSupabase(payload.newRecord!);
            onRemoteChange(note);
          }
        },
      )
      .subscribe();
  }
} 