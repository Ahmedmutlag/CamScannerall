import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/folder.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/folder_card.dart';
import 'folder_screen.dart';

/// The "Files" tab: folder-based organization, for users who want to file
/// documents away rather than rely on the Home tab's flat Recent list.
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedFolderIds = {};

  void _toggleSelection(String folderId) {
    setState(() {
      if (_selectedFolderIds.contains(folderId)) {
        _selectedFolderIds.remove(folderId);
      } else {
        _selectedFolderIds.add(folderId);
      }
    });
  }

  Future<void> _createFolderDialog() async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('newFolder')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: s.t('folderName')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.t('cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(s.t('create')),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await appState.createFolder(name);
    }
  }

  Future<void> _mergeSelected() async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    final folders = appState.db.allFolders.where((f) => _selectedFolderIds.contains(f.id)).toList();
    if (folders.length < 2) return;
    final controller = TextEditingController(text: folders.first.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('merge')),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: s.t('folderName'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(s.t('merge'))),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await appState.mergeFolders(folders, name);
      setState(() {
        _selectionMode = false;
        _selectedFolderIds.clear();
      });
    }
  }

  Future<void> _deleteSelected() async {
    final appState = context.read<AppState>();
    for (final id in _selectedFolderIds) {
      final folder = appState.db.folderById(id);
      if (folder != null) await appState.deleteFolder(folder);
    }
    setState(() {
      _selectionMode = false;
      _selectedFolderIds.clear();
    });
  }

  void _folderTap(Folder folder) {
    if (_selectionMode) {
      _toggleSelection(folder.id);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => FolderScreen(folder: folder)));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;
    final isGrid = appState.db.settings.viewMode == 'grid';
    final folders = appState.db.allFolders;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? '${_selectedFolderIds.length} ${s.t('selected')}' : s.t('files')),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectionMode = false;
                  _selectedFolderIds.clear();
                }),
              )
            : null,
        actions: _selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.merge_type),
                  onPressed: _selectedFolderIds.length >= 2 ? _mergeSelected : null,
                ),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteSelected),
              ]
            : [
                IconButton(
                  icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
                  onPressed: () => appState.setViewMode(isGrid ? 'list' : 'grid'),
                ),
                IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: folders.isEmpty ? null : () => setState(() => _selectionMode = true),
                ),
              ],
      ),
      body: folders.isEmpty
          ? EmptyStateView(
              message: s.t('noFolders'),
              actionLabel: s.t('newFolder'),
              onAction: _createFolderDialog,
            )
          : _buildFolderList(folders, isGrid, appState),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _createFolderDialog,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: Text(s.t('newFolder')),
            ),
    );
  }

  Widget _buildFolderList(List<Folder> folders, bool isGrid, AppState appState) {
    final colors = AppColors.of(context);
    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.1,
        ),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          return FolderCard(
            folder: folder,
            documentCount: appState.db.documentsForFolder(folder.id).length,
            isGrid: true,
            selected: _selectedFolderIds.contains(folder.id),
            selectionMode: _selectionMode,
            onTap: () => _folderTap(folder),
            onLongPress: () => setState(() {
              _selectionMode = true;
              _selectedFolderIds.add(folder.id);
            }),
          );
        },
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: folders.length,
      separatorBuilder: (_, _) => Divider(color: colors.divider, height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
      itemBuilder: (context, index) {
        final folder = folders[index];
        return FolderCard(
          folder: folder,
          documentCount: appState.db.documentsForFolder(folder.id).length,
          isGrid: false,
          selected: _selectedFolderIds.contains(folder.id),
          selectionMode: _selectionMode,
          onTap: () => _folderTap(folder),
          onLongPress: () => setState(() {
            _selectionMode = true;
            _selectedFolderIds.add(folder.id);
          }),
        );
      },
    );
  }
}
