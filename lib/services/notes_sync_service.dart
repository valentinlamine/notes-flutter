import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';
import 'package:realtime_client/realtime_client.dart';

class NotesSyncService {
  final supabase = Supabase.instance.client;

  Future<void> pushNote(Note note, String userId) async {
    try {
      if (note.remoteId == null) {
        final existing = await supabase.from('notes')
          .select('id')
          .eq('user_id', userId)
          .eq('id', note.id)
          .eq('deleted', false)
          .maybeSingle();
        if (existing != null && existing['id'] != null) {
          note.remoteId = existing['id'] as String;
        }
      }
      if (note.remoteId == null) {
        final response = await supabase.from('notes').insert(note.toSupabaseMap(userId)).select().single();
        note.remoteId = response['id'] as String?;
        note.syncStatus = SyncStatus.synced;
        note.lastSyncedAt = DateTime.tryParse(response['updated_at'] ?? '');
      } else {
        final response = await supabase.from('notes').update(note.toSupabaseMap(userId)).eq('id', note.remoteId!).select().single();
        note.syncStatus = SyncStatus.synced;
        note.lastSyncedAt = DateTime.tryParse(response['updated_at'] ?? '');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Note>> pullNotes(String userId) async {
    final response = await supabase.from('notes').select().eq('user_id', userId).eq('deleted', false);
    return (response as List).map((map) => Note.fromSupabase(map)).toList();
  }

  Future<void> resolveConflict(Note local, Note remote, bool keepLocal, String userId) async {
    if (keepLocal) {
      await pushNote(local, userId);
    } else {
    }
  }

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

  Future<void> deleteNoteCloud(Note note, String userId) async {
    if (note.remoteId == null) return;
    try {
      await supabase.from('notes').delete().eq('id', note.remoteId!).eq('user_id', userId);
    } catch (e) {
      print('[SYNC][ERROR] deleteNoteCloud: $e');
    }
  }
} 