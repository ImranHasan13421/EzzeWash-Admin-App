// lib/features/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';

// --- DYNAMIC THEME HELPERS ---
bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
Color _surfaceColor(BuildContext context) => _isDark(context) ? const Color(0xFF1E293B).withOpacity(0.85) : Colors.white.withOpacity(0.85);
Color _textColor(BuildContext context) => _isDark(context) ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
Color _subtextColor(BuildContext context) => _isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
Color _borderColor(BuildContext context) => _isDark(context) ? const Color(0xFF475569).withOpacity(0.5) : const Color(0xFFE2E8F0).withOpacity(0.6);
Color _inputFillColor(BuildContext context) => _isDark(context) ? const Color(0xFF0F172A).withOpacity(0.5) : const Color(0xFFF1F5F9).withOpacity(0.5);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mobile UI State
  String? _expandedGroup;
  int? _tab;

  bool _loading = false;
  bool _isSaving = false;
  bool _isInviting = false;

  // Role Authentication variables
  bool _isSuperAdmin = false;
  String _adminRole = 'Manager';

  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _bizNameCtrl = TextEditingController();
  final _bizGstCtrl = TextEditingController();
  final _bizAddrCtrl = TextEditingController();
  final _bizPhoneCtrl = TextEditingController();
  final _inviteEmailCtrl = TextEditingController();

  String _inviteRole = 'Manager';
  String? _inviteStoreId;

  // Data Lists
  List<Map<String, dynamic>> _teamMembers = [];
  List<Map<String, dynamic>> _storesList = [];
  List<Map<String, dynamic>> _servicesList = [];
  List<Map<String, dynamic>> _customersList = [];
  List<Map<String, dynamic>> _promosList = [];

  String _customerSearchQuery = '';
  User? currentUser;
  String _joinedDate = 'Unknown';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser != null) {
      _nameCtrl.text = currentUser!.userMetadata?['full_name'] as String? ?? 'Admin';
      _phoneCtrl.text = currentUser!.userMetadata?['phone'] as String? ?? '';
      _emailCtrl.text = currentUser!.email ?? '';
      final createdAt = DateTime.tryParse(currentUser!.createdAt);
      if (createdAt != null) {
        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        _joinedDate = '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
      }

      // 1. Fetch user role from database
      try {
        final response = await Supabase.instance.client
            .from('team_members')
            .select('role')
            .eq('email', currentUser!.email!)
            .maybeSingle();

        if (response != null) {
          _adminRole = response['role'] ?? 'Manager';
        }
      } catch (e) {
        debugPrint('Error loading admin details: $e');
      }
    }

    _isSuperAdmin = _adminRole == 'Super Admin';

    // 2. Conditionally load data based on privileges
    await Future.wait([
      if (_isSuperAdmin) _loadBusinessSettings(),
      if (_isSuperAdmin) _loadStores(),
      if (_isSuperAdmin) _loadTeamMembers(),
      if (_isSuperAdmin) _loadCustomers(),
      _loadServices(), // Managers still need access to catalog
      _loadPromos(),   // Managers still need access to active promos
    ]);

    if (mounted) setState(() => _loading = false);
  }

  // --- DATABASE OPERATIONS ---
  Future<void> _loadBusinessSettings() async {
    try {
      final data = await Supabase.instance.client.from('settings').select().eq('id', 1).maybeSingle();
      if (data != null) {
        _bizNameCtrl.text = data['business_name'] ?? '';
        _bizGstCtrl.text = data['gst_number'] ?? '';
        _bizAddrCtrl.text = data['business_address'] ?? '';
        _bizPhoneCtrl.text = data['contact_number'] ?? '';
      }
    } catch (e) { debugPrint('Error: $e'); }
  }

  Future<void> _loadStores() async {
    try {
      final data = await Supabase.instance.client.from('stores').select().order('created_at', ascending: false);
      if (mounted) setState(() => _storesList = List<Map<String, dynamic>>.from(data));
    } catch (e) { debugPrint('Error: $e'); }
  }

  Future<void> _loadTeamMembers() async {
    try {
      final data = await Supabase.instance.client.from('team_members').select('*, stores(name, city)').order('created_at');
      if (mounted) setState(() => _teamMembers = List<Map<String, dynamic>>.from(data));
    } catch (e) { debugPrint('Error: $e'); }
  }

  Future<void> _loadServices() async {
    try {
      final data = await Supabase.instance.client.from('services').select().order('created_at', ascending: false);
      if (mounted) setState(() => _servicesList = List<Map<String, dynamic>>.from(data));
    } catch (e) { debugPrint('Error: $e'); }
  }

  Future<void> _loadCustomers() async {
    try {
      final data = await Supabase.instance.client.from('profiles').select().order('created_at', ascending: false);
      if (mounted) setState(() => _customersList = List<Map<String, dynamic>>.from(data));
    } catch (e) { debugPrint('Error: $e'); }
  }

  Future<void> _loadPromos() async {
    try {
      final data = await Supabase.instance.client.from('promos').select().order('created_at', ascending: false);
      if (mounted) setState(() => _promosList = List<Map<String, dynamic>>.from(data));
    } catch (e) { debugPrint('Error: $e'); }
  }

  Future<void> _toggleServiceStatus(Map<String, dynamic> service) async {
    final newStatus = !(service['is_active'] ?? true);
    try {
      await Supabase.instance.client.from('services').update({'is_active': newStatus}).eq('id', service['id']);
      _loadServices();
      _showToast(newStatus ? '${service['title']} is now Available' : '${service['title']} is now Unavailable', newStatus ? AppColors.success : AppColors.warning);
    } catch (e) { _showToast('Error updating status', AppColors.error); }
  }

  Future<void> _toggleStoreStatus(Map<String, dynamic> store) async {
    final newStatus = !(store['is_active'] ?? true);
    try {
      await Supabase.instance.client.from('stores').update({'is_active': newStatus}).eq('id', store['id']);
      _loadStores();
      _showToast(newStatus ? '${store['name']} is now Open' : '${store['name']} is now Closed', newStatus ? AppColors.success : AppColors.warning);
    } catch (e) { _showToast('Error updating store', AppColors.error); }
  }

  Future<void> _togglePromoStatus(Map<String, dynamic> promo) async {
    final newStatus = !(promo['is_active'] ?? true);
    try {
      await Supabase.instance.client.from('promos').update({'is_active': newStatus}).eq('id', promo['id']);
      _loadPromos();
      _showToast(newStatus ? 'Promo activated' : 'Promo moved to history', newStatus ? AppColors.success : AppColors.warning);
    } catch (e) { _showToast('Error updating promo', AppColors.error); }
  }

  // --- UI COMPONENTS ---
  Widget _buildCategoryCard(String title, IconData icon, String groupId, String subtitle) {
    final isExpanded = _expandedGroup == groupId;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_expandedGroup == groupId) {
            _expandedGroup = null;
            _tab = null;
          } else {
            _expandedGroup = groupId;
            _tab = null;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isExpanded ? AppColors.primary.withOpacity(0.04) : _surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isExpanded ? AppColors.primary.withOpacity(0.6) : _borderColor(context), width: isExpanded ? 2 : 1),
          boxShadow: isExpanded ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isExpanded ? AppColors.primary : _inputFillColor(context), shape: BoxShape.circle, border: Border.all(color: _borderColor(context))),
              child: Icon(icon, color: isExpanded ? Colors.white : AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: isExpanded ? AppColors.primary : _textColor(context))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: _subtextColor(context))),
                ],
              ),
            ),
            Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: isExpanded ? AppColors.primary : _subtextColor(context), size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3. Dynamically build available tabs based on role
    final List<Map<String, dynamic>> tabs = [
      {'id': 'profile', 'name': 'Profile', 'icon': Icons.person_outline},
      {'id': 'security', 'name': 'Security', 'icon': Icons.shield_outlined},
      if (_isSuperAdmin) {'id': 'team', 'name': 'Team', 'icon': Icons.people_outline},
      if (_isSuperAdmin) {'id': 'business', 'name': 'Business Info', 'icon': Icons.business_center_outlined},

      if (_isSuperAdmin) {'id': 'customers', 'name': 'Customers', 'icon': Icons.manage_accounts_outlined},
      {'id': 'promos', 'name': 'Promos', 'icon': Icons.campaign_outlined},
      if (_isSuperAdmin) {'id': 'stores', 'name': 'Stores', 'icon': Icons.store_mall_directory_outlined},
      {'id': 'services', 'name': 'Services', 'icon': Icons.dry_cleaning_outlined},
    ];

    if (_tab != null && _tab! >= tabs.length) _tab = null;

    final adminTabIds = ['profile', 'security', 'team', 'business'];
    final bizTabIds = ['customers', 'promos', 'stores', 'services'];

    final adminTabs = tabs.where((t) => adminTabIds.contains(t['id'])).toList();
    final bizTabs = tabs.where((t) => bizTabIds.contains(t['id'])).toList();

    Widget buildTabRow(List<Map<String, dynamic>> tabGroup) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        height: 45,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: tabGroup.length,
          itemBuilder: (ctx, i) {
            final t = tabGroup[i];
            final realIndex = tabs.indexOf(t);
            final sel = _tab == realIndex;
            return GestureDetector(
              onTap: () {
                setState(() { _tab = realIndex; _isInviting = false; });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : _surfaceColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? AppColors.primary : _borderColor(context)),
                ),
                child: Row(children: [
                  Icon(t['icon'] as IconData, size: 16, color: sel ? Colors.white : _subtextColor(context)),
                  const SizedBox(width: 8),
                  Text(t['name'] as String, style: GoogleFonts.inter(color: sel ? Colors.white : _subtextColor(context), fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
              ),
            );
          },
        ),
      );
    }

    return Column(
      children: [
        // Header (Sign out removed)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Text('Settings', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: _textColor(context))),
            ],
          ),
        ),

        // Body
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildCategoryCard('Administration', Icons.admin_panel_settings_outlined, 'admin', 'Profile, security${_isSuperAdmin ? ' & team' : ''}'),
              if (_expandedGroup == 'admin') buildTabRow(adminTabs),

              const SizedBox(height: 16),

              _buildCategoryCard('Business', Icons.storefront_outlined, 'business', '${_isSuperAdmin ? 'Customers, promos & services' : 'Promos & services'}'),
              if (_expandedGroup == 'business') buildTabRow(bizTabs),

              if (_tab != null)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey<int>(_tab!),
                    margin: const EdgeInsets.only(top: 16),
                    child: Builder(builder: (context) {
                      final id = tabs[_tab!]['id'];
                      if (id == 'profile') return _profileTab();
                      if (id == 'security') return _securityTab();
                      if (id == 'team' && _isSuperAdmin) return _teamTab();
                      if (id == 'business' && _isSuperAdmin) return _businessTab();
                      if (id == 'customers' && _isSuperAdmin) return _customersTab();
                      if (id == 'promos') return _promosTab();
                      if (id == 'stores' && _isSuperAdmin) return _storesTab();
                      if (id == 'services') return _servicesTab();
                      return const SizedBox.shrink();
                    }),
                  ),
                ),

              const SizedBox(height: 48), // Bottom padding
            ],
          ),
        ),
      ],
    );
  }

  // --- MOBILE ADAPTED TABS ---

  Widget _profileTab() {
    return _sectionCard(
      title: 'Profile Info',
      icon: Icons.person_outline,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary,
            child: Text(_nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'U', style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_nameCtrl.text, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor(context))),
              Text(_emailCtrl.text, style: GoogleFonts.inter(fontSize: 13, color: _subtextColor(context))),
              const SizedBox(height: 4),
              _roleBadge(_adminRole), // Uses the actual database role
            ]),
          )
        ]),
        const SizedBox(height: 24),
        _textField('Full Name', _nameCtrl),
        const SizedBox(height: 16),
        _textField('Phone Number', _phoneCtrl, hint: '+8801XXXXXXXXX'),
        const SizedBox(height: 24),
        _actionButton('Save Changes', AppColors.primary, Icons.save_rounded, () async {
          setState(() => _isSaving = true);
          try {
            await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'full_name': _nameCtrl.text.trim(), 'phone': _phoneCtrl.text.trim()}));
            _showToast('Profile updated!', AppColors.success);
          } catch (e) { _showToast('Error', AppColors.error); }
          setState(() => _isSaving = false);
        }),
      ]),
    );
  }

  Widget _securityTab() {
    return _sectionCard(
        title: 'Security',
        icon: Icons.shield_outlined,
        iconColor: AppColors.accent,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _textField('Change Name', _nameCtrl),
          const SizedBox(height: 16),
          _textField('Change Password', _passCtrl, obscure: true),
          const SizedBox(height: 16),
          _textField('Change Email', _emailCtrl),
          const SizedBox(height: 24),
          _actionButton('Save Security', AppColors.primary, Icons.lock_outline, () async {
            setState(() => _isSaving = true);
            try {
              if (_passCtrl.text.isNotEmpty && _passCtrl.text.length >= 6) {
                await Supabase.instance.client.auth.updateUser(UserAttributes(password: _passCtrl.text.trim()));
              }
              await Supabase.instance.client.auth.updateUser(UserAttributes(email: _emailCtrl.text.trim()));
              _passCtrl.clear();
              _showToast('Security updated!', AppColors.success);
            } catch (e) { _showToast('Error', AppColors.error); }
            setState(() => _isSaving = false);
          }),
        ])
    );
  }

  Widget _teamTab() {
    return _sectionCard(
        title: 'Team Members',
        icon: Icons.people_outline,
        subtitle: '${_teamMembers.length + 1} members',
        actionWidget: IconButton(
          onPressed: () => setState(() => _isInviting = !_isInviting),
          icon: Icon(_isInviting ? Icons.close : Icons.person_add_outlined, color: AppColors.primary),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_isInviting) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _inputFillColor(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor(context))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invite Member', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: _textColor(context))),
                  const SizedBox(height: 16),
                  _textField('Email Address', _inviteEmailCtrl),
                  const SizedBox(height: 12),
                  Text('Assign Store', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: _textColor(context))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _inviteStoreId,
                    decoration: _inputDeco(),
                    dropdownColor: _surfaceColor(context),
                    items: _storesList.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name'], style: TextStyle(fontSize: 14, color: _textColor(context))))).toList(),
                    onChanged: (v) => setState(() => _inviteStoreId = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: _actionButton('Add Member', AppColors.success, Icons.check, () async {
                    if (_inviteEmailCtrl.text.isEmpty || _inviteStoreId == null) return _showToast('Fill all fields', AppColors.warning);
                    try {
                      await Supabase.instance.client.from('team_members').insert({'email': _inviteEmailCtrl.text.trim(), 'role': _inviteRole, 'store_id': _inviteStoreId});
                      _inviteEmailCtrl.clear(); _inviteStoreId = null; setState(() => _isInviting = false);
                      await _loadTeamMembers(); _showToast('Member added!', AppColors.success);
                    } catch(e) { _showToast('Error', AppColors.error); }
                  })),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Text('A', style: TextStyle(color: Colors.white))),
            title: Text('Admin', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _textColor(context))),
            subtitle: Text('Global Access', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary)),
            trailing: _roleBadge('Super Admin'),
          ),
          const Divider(),
          ..._teamMembers.map((m) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: AppColors.accent, child: Text(m['email'][0].toUpperCase(), style: const TextStyle(color: Colors.white))),
            title: Text(m['email'].split('@')[0], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _textColor(context))),
            subtitle: Text(m['stores']?['name'] ?? 'Unassigned', style: GoogleFonts.inter(fontSize: 12, color: _subtextColor(context))),
            trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: () async {
              await Supabase.instance.client.from('team_members').delete().eq('id', m['id']);
              _loadTeamMembers();
            }),
          )),
        ])
    );
  }

  Widget _businessTab() {
    return _sectionCard(title: 'Business Info', icon: Icons.business, child: Column(children: [
      _textField('Business Name', _bizNameCtrl), const SizedBox(height: 16),
      _textField('Tax Number', _bizGstCtrl), const SizedBox(height: 16),
      _textField('Address', _bizAddrCtrl), const SizedBox(height: 16),
      _textField('Phone', _bizPhoneCtrl), const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: _actionButton('Save Info', AppColors.primary, Icons.save, () async {
        try { await Supabase.instance.client.from('settings').upsert({'id': 1, 'business_name': _bizNameCtrl.text, 'gst_number': _bizGstCtrl.text, 'business_address': _bizAddrCtrl.text, 'contact_number': _bizPhoneCtrl.text}); _showToast('Saved', AppColors.success); } catch (e) { _showToast('Error', AppColors.error); }
      }))
    ]));
  }

  Widget _customersTab() {
    final filtered = _customersList.where((c) {
      final q = _customerSearchQuery.toLowerCase();
      final n = (c['full_name'] ?? '').toString().toLowerCase();
      final p = (c['phone'] ?? '').toString().toLowerCase();
      return n.contains(q) || p.contains(q);
    }).toList();

    return _sectionCard(
        title: 'Customers', subtitle: '${_customersList.length} users', icon: Icons.group, iconColor: Colors.amber,
        child: Column(children: [
          TextField(
            onChanged: (v) => setState(() => _customerSearchQuery = v),
            decoration: _inputDeco(hint: 'Search users...').copyWith(prefixIcon: const Icon(Icons.search)),
          ),
          const SizedBox(height: 16),
          ...filtered.map((c) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: const Icon(Icons.person, color: AppColors.primary)),
            title: Text(c['full_name'] ?? 'Unknown', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _textColor(context))),
            subtitle: Text(c['phone'] ?? 'No phone', style: GoogleFonts.inter(fontSize: 12, color: _subtextColor(context))),
            trailing: TextButton(onPressed: () => _showCustomerOrderHistory(c), child: const Text('Orders')),
          ))
        ])
    );
  }

  void _showCustomerOrderHistory(Map<String, dynamic> customer) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Container(
      height: MediaQuery.of(context).size.height * 0.7, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _surfaceColor(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${customer['full_name']} Orders', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        const Divider(),
        Expanded(child: FutureBuilder(future: Supabase.instance.client.from('orders').select().eq('user_id', customer['id']).order('created_at', ascending: false), builder: (c, snap) {
          if(!snap.hasData) return const Center(child: CircularProgressIndicator());
          if(snap.data!.isEmpty) return const Center(child: Text('No orders.'));
          return ListView.separated(itemCount: snap.data!.length, separatorBuilder: (_,__) => const Divider(), itemBuilder: (c, i) {
            final o = snap.data![i];
            return ListTile(title: Text('#${o['order_number']}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(o['status']), trailing: Text('৳${o['total_price']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)));
          });
        }))
      ]),
    ));
  }

  Widget _promosTab() {
    return _sectionCard(
        title: 'Promotions', icon: Icons.campaign, iconColor: AppColors.accent,
        actionWidget: IconButton(icon: const Icon(Icons.add_circle, color: AppColors.accent), onPressed: () => _showAddPromoDialog(null)),
        child: Column(children: [
          ..._promosList.map((p) => Card(
              color: _inputFillColor(context), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _borderColor(context))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(
                      child: Text(
                        p['title'] ?? 'Promo',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch(value: p['is_active'] ?? false, activeColor: AppColors.success, onChanged: (_) => _togglePromoStatus(p)),
                  ]),
                  Text(p['code'].toString().toUpperCase(), style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(
                      child: Text(
                        'Used: ${p['times_used'] ?? 0}/${p['usage_limit'] ?? '∞'}',
                        style: TextStyle(fontSize: 12, color: _subtextColor(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: () => _showAddPromoDialog(p)),
                      IconButton(icon: const Icon(Icons.delete, size: 18, color: AppColors.error), onPressed: () async { await Supabase.instance.client.from('promos').delete().eq('id', p['id']); _loadPromos(); }),
                    ])
                  ])
                ]),
              )
          ))
        ])
    );
  }

  void _showAddPromoDialog(Map<String, dynamic>? promo) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promo management is optimized for the desktop portal.')));
  }

  Widget _storesTab() {
    return _sectionCard(title: 'Stores', icon: Icons.store,
        actionWidget: IconButton(icon: const Icon(Icons.add_circle, color: AppColors.primary), onPressed: () => _showAddOrEditStoreDialog(null)),
        child: Column(children: _storesList.map((s) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s['name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          subtitle: Text(s['address'], style: const TextStyle(fontSize: 12)),
          trailing: Switch(value: s['is_active'] ?? true, activeColor: AppColors.success, onChanged: (_) => _toggleStoreStatus(s)),
        )).toList())
    );
  }

  void _showAddOrEditStoreDialog(Map<String, dynamic>? store) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store configuration is optimized for the desktop portal.')));
  }

  Widget _servicesTab() {
    return _sectionCard(title: 'Services', icon: Icons.dry_cleaning,
        actionWidget: IconButton(icon: const Icon(Icons.add_circle, color: AppColors.primary), onPressed: () => _showAddOrEditServiceDialog(null)),
        child: Column(children: _servicesList.map((s) => Card(
            color: _inputFillColor(context), elevation: 0, margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _borderColor(context))),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  Container(height: 50, width: 50, decoration: BoxDecoration(color: _borderColor(context), borderRadius: BorderRadius.circular(8), image: s['image_url'] != null ? DecorationImage(image: NetworkImage(s['image_url']), fit: BoxFit.cover) : null), child: s['image_url'] == null ? const Icon(Icons.image, color: Colors.grey) : null),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s['title'], style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    Text('৳${s['price']} • ${s['duration']}', style: TextStyle(color: _subtextColor(context), fontSize: 12)),
                  ])),
                  Switch(value: s['is_active'] ?? true, activeColor: AppColors.success, onChanged: (_) => _toggleServiceStatus(s))
                ]),
              ]),
            )
        )).toList())
    );
  }

  void _showAddOrEditServiceDialog(Map<String, dynamic>? service) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service configuration is optimized for the desktop portal.')));
  }

  // --- REUSABLE COMPONENTS ---
  Widget _sectionCard({required String title, String? subtitle, required IconData icon, Color iconColor = AppColors.primary, Widget? actionWidget, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _surfaceColor(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderColor(context))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor(context))), if(subtitle != null) Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: _subtextColor(context)))])),
          if (actionWidget != null) actionWidget
        ]),
        const SizedBox(height: 24),
        child
      ]),
    );
  }

  Widget _textField(String label, TextEditingController ctrl, {bool obscure = false, String? hint}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: _textColor(context))),
      const SizedBox(height: 6),
      TextFormField(controller: ctrl, obscureText: obscure, style: TextStyle(fontSize: 14, color: _textColor(context)), decoration: _inputDeco(hint: hint)),
    ]);
  }

  InputDecoration _inputDeco({String? hint}) => InputDecoration(hintText: hint, hintStyle: TextStyle(color: _subtextColor(context).withOpacity(0.5)), filled: true, fillColor: _inputFillColor(context), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _borderColor(context))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _borderColor(context))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)));

  Widget _actionButton(String label, Color color, IconData icon, VoidCallback onTap) => ElevatedButton.icon(onPressed: _isSaving ? null : onTap, icon: Icon(icon, size: 16, color: Colors.white), label: Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  Widget _roleBadge(String role) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(role, style: GoogleFonts.inter(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)));

  void _showToast(String msg, Color color) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color)); }
}