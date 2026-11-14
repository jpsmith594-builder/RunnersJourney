import 'package:flutter/material.dart';

import 'bucket_form_screen.dart';
import 'bucket_item.dart';
import 'bucket_store.dart';
import '../../core/units.dart';

/// The race bucket list: races the runner wants to do, with a tickbox each.
/// Open races show as grey pins on the map; ticked ones come off the map.
class BucketListScreen extends StatelessWidget {
  final BucketStore store;
  const BucketListScreen({super.key, required this.store});

  void _open(BuildContext context, [BucketItem? item]) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => BucketFormScreen(store: store, item: item)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Race bucket list')),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (store.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (store.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  store.error != null
                      ? 'Could not load your bucket list.\n${store.error}\n\n'
                          'Have you run supabase/005_bucket_list.sql?'
                      : 'Nothing here yet.\nAdd the races you dream of running.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final items = [...store.items]
            ..sort((a, b) => a.done == b.done ? 0 : (a.done ? 1 : -1));
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final it = items[i];
              final sub = [
                if (it.locationName != null) it.locationName!,
                if (it.distanceKm != null) formatDistance(it.distanceKm!),
              ].join('  ·  ');
              return Dismissible(
                key: ValueKey(it.id ?? it.name),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red.shade400,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => store.delete(it),
                child: ListTile(
                  leading: Checkbox(
                    value: it.done,
                    onChanged: (v) => store.setDone(it, v ?? false),
                  ),
                  title: Text(
                    it.name,
                    style: it.done
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey)
                        : null,
                  ),
                  subtitle: sub.isEmpty ? null : Text(sub),
                  trailing: IconButton(
                    tooltip: 'Remove from bucket list',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      if (await confirmRemoveBucketItem(context, it)) {
                        store.delete(it);
                      }
                    },
                  ),
                  onTap: () => _open(context, it),
                ),
              );
            },
          );
        },
      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context),
        icon: const Icon(Icons.add),
        label: const Text('Add race'),
      ),
    );
  }
}
