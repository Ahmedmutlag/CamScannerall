import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/document.dart';
import '../models/folder.dart';
import '../services/quick_scan_flow.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/folder_card.dart';
import 'document_detail_screen.dart';
import 'folder_screen.dart';
import 'settings_screen.dart';
import 'timeline_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _selectionMode = false;
  final Set<String> _selectedFolderIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    final searching = _query.trim().isNotEmpty;
    final searchResults = searching ? appState.db.search(_query) : <Document>[];
    final folders = appState.db.allFolders;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode
            ? '${_selectedFolderIds.length} ${s.t('selected')}'
            : s.t('appName')),
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
                  icon: const Icon(Icons.history),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TimelineScreen())),
                ),
                IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: folders.isEmpty ? null : () => setState(() => _selectionMode = true),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: s.t('search'),
              ),
            ),
          ),
          Expanded(
            child: searching
                ? _buildSearchResults(searchResults, appState)
                : folders.isEmpty
                    ? EmptyStateView(
                        message: s.t('noFolders'),
                        actionLabel: s.t('newFolder'),
                        onAction: _createFolderDialog,
                      )
                    : _buildFolderList(folders, isGrid, appState),
          ),
        ],
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddMenu,
              icon: const Icon(Icons.add),
              label: Text(s.t('newFolder')),
            ),
    );
  }

  Widget _buildSearchResults(List<Document> results, AppState appState) {
    final colors = AppColors.of(context);
    if (results.isEmpty) {
      return EmptyStateView(message: appState.strings.t('noSearchResults'));
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => Divider(color: colors.divider, height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
      itemBuilder: (context, index) {
        final doc = results[index];
        return ListTile(
          leading: Icon(Icons.description_outlined, color: colors.primaryInk),
          title: Text(doc.name),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)),
          ),
        );
      },
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

  Future<void> _showAddMenu() async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(s.t('newFolder')),
              onTap: () {
                Navigator.pop(context);
                _createFolderDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bolt_outlined),
              title: Text(s.t('scanQuick')),
              onTap: () {
                Navigator.pop(context);
                runQuickScanAndShare(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
