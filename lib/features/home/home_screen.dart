import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../updater/widgets/update_floating_card.dart';
import '../../core/providers.dart';
import '../../widgets/totp_account_card.dart';
import '../../database/database.dart';
import 'package:drift/drift.dart' as drift;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearchExpanded = false;
  final Set<int> _selectedIds = {};

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _togglePinSelectedAccounts(bool pin) async {
    final accounts = ref.read(watchAccountsProvider).value ?? [];
    final toUpdate = accounts.where((acc) => _selectedIds.contains(acc.id)).toList();
    for (final acc in toUpdate) {
      await ref.read(accountRepositoryProvider).updateAccount(acc.copyWith(isPinned: pin));
    }
    setState(() {
      _selectedIds.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${toUpdate.length} account(s) ${pin ? 'pinned' : 'unpinned'}')),
      );
    }
  }

  Future<void> _deleteSelectedAccounts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Accounts'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} account(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final accounts = ref.read(watchAccountsProvider).value ?? [];
      final toDelete = accounts.where((acc) => _selectedIds.contains(acc.id)).toList();
      for (final acc in toDelete) {
        await ref.read(accountRepositoryProvider).deleteAccount(acc);
      }
      setState(() {
        _selectedIds.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${toDelete.length} account(s) deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortOrder = ref.watch(sortOrderProvider);
    
    final bool isSelectionMode = _selectedIds.isNotEmpty;
    
    final accountsList = ref.watch(watchAccountsProvider).value ?? [];
    final selectedAccounts = accountsList.where((acc) => _selectedIds.contains(acc.id)).toList();
    final allSelectedArePinned = selectedAccounts.isNotEmpty && selectedAccounts.every((acc) => acc.isPinned);

    return Stack(
      children: [
        Scaffold(
          appBar: isSelectionMode 
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedIds.clear()),
                ),
                title: Text('${_selectedIds.length} selected'),
                actions: [
                  IconButton(
                    icon: Icon(allSelectedArePinned ? Icons.push_pin_outlined : Icons.push_pin),
                    tooltip: allSelectedArePinned ? 'Unpin Selected' : 'Pin Selected',
                    onPressed: () => _togglePinSelectedAccounts(!allSelectedArePinned),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_2),
                    tooltip: 'Export Selected',
                    onPressed: () {
                      final accounts = ref.read(watchAccountsProvider).value ?? [];
                      final toExport = accounts.where((acc) => _selectedIds.contains(acc.id)).toList();
                      setState(() => _selectedIds.clear());
                      context.push('/export', extra: toExport);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete Selected',
                    onPressed: _deleteSelectedAccounts,
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'More options',
                    onSelected: (value) {
                      if (value == 'move_tag') {
                        // TODO: Implement move tag logic
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'move_tag',
                        child: Row(
                          children: [
                            Icon(Icons.label_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Move Tag'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : AppBar(
                title: _isSearchExpanded
                  ? TextField(
                      key: const ValueKey('search'),
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search accounts...',
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).setQuery(val.toLowerCase());
                      },
                    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1, end: 0)
                  : const Text('SafeKey', key: ValueKey('title'), style: TextStyle(fontWeight: FontWeight.bold))
                      .animate().fadeIn(duration: 200.ms).slideX(begin: -0.1, end: 0),
            actions: [
              IconButton(
                icon: Icon(_isSearchExpanded ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearchExpanded = !_isSearchExpanded;
                  });
                  if (!_isSearchExpanded) {
                    ref.read(searchQueryProvider.notifier).setQuery('');
                  }
                },
              ),
              if (!_isSearchExpanded)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort/Group',
                  onSelected: (value) {
                    if (value == 'select_mode') {
                      setState(() {
                        _selectedIds.clear();
                      });
                      final accounts = ref.read(watchAccountsProvider).value ?? [];
                      if (accounts.isNotEmpty) {
                        _toggleSelection(accounts.first.id);
                      }
                    } else {
                      ref.read(sortOrderProvider.notifier).setSortOrder(value);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'custom',
                      child: Row(
                        children: [
                          const Icon(Icons.drag_handle, size: 20),
                          const SizedBox(width: 8),
                          Text('Custom Order', style: TextStyle(fontWeight: sortOrder == 'custom' ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'select_mode',
                      child: Row(
                        children: [
                          const Icon(Icons.checklist, size: 20),
                          const SizedBox(width: 8),
                          const Text('Select Accounts'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'recent',
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 20),
                          const SizedBox(width: 8),
                          Text('Recently Added', style: TextStyle(fontWeight: sortOrder == 'recent' ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'name',
                      child: Row(
                        children: [
                          const Icon(Icons.sort_by_alpha, size: 20),
                          const SizedBox(width: 8),
                          Text('Alphabetical', style: TextStyle(fontWeight: sortOrder == 'name' ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'issuer',
                      child: Row(
                        children: [
                          const Icon(Icons.work_outline, size: 20),
                          const SizedBox(width: 8),
                          Text('Group by Issuer', style: TextStyle(fontWeight: sortOrder == 'issuer' ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    ),
                  ],
                ),
              if (!_isSearchExpanded)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    context.push('/settings');
                  },
                ),
            ],
          ),
          body: ref.watch(watchAccountsProvider).when(
            data: (accounts) {
              if (accounts.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.security_rounded,
                              size: 80,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'SafeKey',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your authenticator is empty.',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan your first QR code or manually add an account to get started.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 48),
                          FilledButton.icon(
                            onPressed: () => context.push('/scanner'),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan QR Code'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => context.push('/add'),
                            icon: const Icon(Icons.keyboard),
                            label: const Text('Add Manually'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuart),
                      ),
                    ),
                  ),
                );
              }

              final activeFilter = ref.watch(activeFilterProvider);
              final searchQuery = ref.watch(searchQueryProvider);

              // Gather unique tags
              final allTags = accounts
                  .map((a) => a.tags)
                  .where((t) => t.isNotEmpty)
                  .expand((t) => t.split(','))
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toSet()
                  .toList()..sort();
              
              final bool hasTags = allTags.isNotEmpty || activeFilter != 'All';

              var filteredAccounts = accounts.where((acc) {
                final matchesSearch = acc.issuer.toLowerCase().contains(searchQuery) ||
                                      acc.accountName.toLowerCase().contains(searchQuery);
                
                bool matchesFilter = true;
                if (activeFilter == 'Pinned') {
                  matchesFilter = acc.isPinned;
                } else if (activeFilter != 'All') {
                  final accTags = acc.tags.split(',').map((e) => e.trim()).toList();
                  matchesFilter = accTags.contains(activeFilter);
                }

                return matchesSearch && matchesFilter;
              }).toList();
              
              if (sortOrder == 'name') {
                filteredAccounts.sort((a, b) => a.accountName.toLowerCase().compareTo(b.accountName.toLowerCase()));
              } else if (sortOrder == 'issuer') {
                filteredAccounts.sort((a, b) => a.issuer.toLowerCase().compareTo(b.issuer.toLowerCase()));
              } else if (sortOrder == 'custom') {
                filteredAccounts.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
              } else {
                filteredAccounts.sort((a, b) => b.id.compareTo(a.id));
              }

              var pinned = filteredAccounts.where((a) => a.isPinned).toList();
              var unpinned = filteredAccounts.where((a) => !a.isPinned).toList();
              filteredAccounts = [...pinned, ...unpinned];

              Widget bodyContent;

              if (filteredAccounts.isEmpty) {
                bodyContent = Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No matching accounts', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Try another search or remove filters.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 24),
                      if (searchQuery.isNotEmpty || activeFilter != 'All')
                        FilledButton.tonal(
                          onPressed: () {
                            ref.read(searchQueryProvider.notifier).setQuery('');
                            ref.read(activeFilterProvider.notifier).setFilter('All');
                            setState(() { _isSearchExpanded = false; });
                          },
                          child: const Text('Clear Filters'),
                        ),
                    ],
                  ).animate().fadeIn(),
                );
              } else {
                bodyContent = ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  onReorderItem: (oldIndex, newIndex) async {
                    if (searchQuery.isNotEmpty || activeFilter != 'All') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot reorder while filtering')));
                      return;
                    }
                    if (sortOrder != 'custom') {
                      ref.read(sortOrderProvider.notifier).setSortOrder('custom');
                    }
                    
                    final currentList = List<Account>.from(filteredAccounts);
                    final item = currentList.removeAt(oldIndex);
                    currentList.insert(newIndex, item);

                    final repo = ref.read(accountRepositoryProvider);
                    for (int i = 0; i < currentList.length; i++) {
                      final acc = currentList[i];
                      if (acc.sortIndex != i) {
                        await repo.updateAccount(acc.copyWith(sortIndex: i));
                      }
                    }
                  },
                itemCount: filteredAccounts.length,
                itemBuilder: (context, index) {
                  final account = filteredAccounts[index];
                  return Dismissible(
                    key: ValueKey(account.id),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      if (isSelectionMode) return false;
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Account'),
                          content: Text('Are you sure you want to delete ${account.accountName}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      ref.read(accountRepositoryProvider).deleteAccount(account);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${account.accountName} deleted')),
                      );
                    },
                    child: ReorderableDelayedDragStartListener(
                      index: index,
                      child: TotpAccountCard(
                        account: account,
                        isSelected: _selectedIds.contains(account.id),
                        onLongPress: null,
                        onTap: isSelectionMode ? () => _toggleSelection(account.id) : null,
                      ),
                    ),
                  ).animate(key: ValueKey('anim_${account.id}')).fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOutQuad);
                },
              );
              }

              return Column(
                children: [
                  if (hasTags)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutQuart,
                      height: 56,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        children: [
                          _buildFilterChip('All', activeFilter),
                          _buildFilterChip('Pinned', activeFilter),
                          ...allTags.map((t) => _buildFilterChip(t, activeFilter)),
                        ],
                      ),
                    ),
                  Expanded(child: bodyContent),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showAddAccountOptions(context);
            },
            child: const Icon(Icons.add),
          ),
        ),
        const UpdateFloatingCard(),
      ],
    );
  }

  void _showAddAccountOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Scan QR Code'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/scanner');
                },
              ),
              ListTile(
                leading: const Icon(Icons.import_export),
                title: const Text('Import from Google Authenticator'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/scanner?mode=google');
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_paste),
                title: const Text('Paste URI'),
                onTap: () {
                  Navigator.pop(context);
                  _showPasteUriDialog(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.keyboard),
                title: const Text('Enter Secret Manually'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/add');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  void _showPasteUriDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste URI'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'otpauth://totp/...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processUri(controller.text.trim());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _processUri(String uriString) async {
    if (!uriString.startsWith('otpauth://')) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid URI format')));
      return;
    }
    // We will parse it and add it
    // Wait, the logic is in ScannerScreen. Let's move it here or just duplicate it for now.
    try {
      final uri = Uri.parse(uriString);
      final queryParams = uri.queryParameters;
      final secret = queryParams['secret']?.toUpperCase().replaceAll(' ', '') ?? '';
      
      if (secret.isEmpty) throw Exception('No secret found');
      
      String issuer = queryParams['issuer'] ?? '';
      String accountName = '';
      
      final pathParts = uri.path.substring(1).split(':');
      if (pathParts.length > 1) {
        if (issuer.isEmpty) issuer = Uri.decodeComponent(pathParts[0]);
        accountName = Uri.decodeComponent(pathParts.sublist(1).join(':'));
      } else if (pathParts.isNotEmpty) {
        accountName = Uri.decodeComponent(pathParts[0]);
      }
      
      if (issuer.isEmpty) issuer = 'Unknown';
      if (accountName.isEmpty) accountName = 'Unknown';

      final algorithm = queryParams['algorithm'] ?? 'SHA1';
      final digits = int.tryParse(queryParams['digits'] ?? '6') ?? 6;
      
      final newAccount = AccountsCompanion.insert(
        issuer: issuer,
        accountName: accountName,
        secret: secret,
        algorithm: drift.Value(algorithm),
        digits: drift.Value(digits),
      );

      await ref.read(accountRepositoryProvider).insertAccount(newAccount);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account added successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to parse URI')));
    }
  }

  Widget _buildFilterChip(String label, String activeFilter) {
    final bool isSelected = label == activeFilter;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            ref.read(activeFilterProvider.notifier).setFilter(label);
          } else if (label != 'All') {
            ref.read(activeFilterProvider.notifier).setFilter('All');
          }
        },
      ),
    );
  }

}
