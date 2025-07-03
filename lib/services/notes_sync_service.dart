import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';
import 'package:realtime_client/realtime_client.dart';

class NotesSyncService {
  final supabase = Supabase.instance.client;

  // Push une note locale vers Supabase (insert ou update)
  Future<void> pushNote(Note note, String userId) async {
    try {
      if (note.remoteId == null) {
        // Chercher une note existante avec le même id
        print('[SYNC] Recherche d\'une note existante pour user_id=$userId, id=${note.id}');
        final existing = await supabase.from('notes')
          .select('id')
          .eq('user_id', userId)
          .eq('id', note.id)
          .eq('deleted', false)
          .maybeSingle();
        if (existing != null && existing['id'] != null) {
          print('[SYNC] Note existante trouvée, update au lieu d\'insert');
          note.remoteId = existing['id'] as String;
        }
      }
      if (note.remoteId == null) {
        print('[SYNC] Insertion Supabase pour la note: ${note.title}');
        final response = await supabase.from('notes').insert(note.toSupabaseMap(userId)).select().single();
        print('[SYNC] Réponse insert: $response');
        note.remoteId = response['id'] as String?;
        note.syncStatus = SyncStatus.synced;
        note.lastSyncedAt = DateTime.tryParse(response['updated_at'] ?? '');
      } else {
        print('[SYNC] Update Supabase pour la note: ${note.title} (id: ${note.remoteId})');
        final response = await supabase.from('notes').update(note.toSupabaseMap(userId)).eq('id', note.remoteId!).select().single();
        print('[SYNC] Réponse update: $response');
        note.syncStatus = SyncStatus.synced;
        note.lastSyncedAt = DateTime.tryParse(response['updated_at'] ?? '');
      }
    } catch (e) {
      print('[SYNC][ERROR] pushNote: $e');
      rethrow;
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
      .on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: '*',
          schema: 'public',
          table: 'notes',
          filter: 'user_id=eq.$userId',
        ),
        (payload, [ref]) {
          if (payload['new'] != null) {
            final note = Note.fromSupabase(payload['new']);
            onRemoteChange(note);
          }
        },
      )
      .subscribe();
  }

  // Suppression cloud (hard delete)
  Future<void> deleteNoteCloud(Note note, String userId) async {
    if (note.remoteId == null) return;
    try {
      print('[SYNC] Suppression cloud (hard delete) pour la note: ${note.title}');
      await supabase.from('notes').delete().eq('id', note.remoteId!).eq('user_id', userId);
    } catch (e) {
      print('[SYNC][ERROR] deleteNoteCloud: $e');
    }
  }
} 