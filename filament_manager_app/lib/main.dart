import 'package:filament_manager_app/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(FilamentManagerApp());
}

Future<void> initSharedPref() async {
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('server')) {
    prefs.setString('server', '192.168.2.219');
    prefs.setInt('port', 5432);
    prefs.setString('username', 'printer');
    prefs.setString('password', 'printer');
    prefs.setString('database', 'printer');
  }
}

Future<ServerSettings> getServerSettings() async {
  await initSharedPref();

  final prefs = await SharedPreferences.getInstance();
  final server = prefs.getString('server')!;
  final port = prefs.getInt('port')!;
  final username = prefs.getString('username')!;
  final password = prefs.getString('password')!;
  final database = prefs.getString('database')!;

  return ServerSettings(server, port, username, password, database);
}

class FilamentManagerApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filament Manager',
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        toggleableActiveColor: darkColorScheme.primary,
        inputDecorationTheme: const InputDecorationTheme(border: UnderlineInputBorder()),
      ),
      theme: ThemeData(
          useMaterial3: true,
          tabBarTheme: TabBarTheme.of(context).copyWith(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black45,
          ),
          colorScheme: lightColorScheme,
          toggleableActiveColor: lightColorScheme.primary,
          inputDecorationTheme: const InputDecorationTheme(border: UnderlineInputBorder())),
      home: const OverviewPage(),
    );
  }
}

class FilamentSpool {
  double initialWeight = 0;
  double usedWeight = 0;
  String name = '';
  double cost;

  FilamentSpool(this.initialWeight, this.usedWeight, this.name, this.cost);
}

class FilamentProfile {
  int id;
  String vendor;
  String material;
  double density;
  double diameter;

  FilamentProfile(this.id, this.vendor, this.material, this.density, this.diameter);
}

class ServerSettings {
  final String server;
  final int port;
  final String username;
  final String password;
  final String database;

  ServerSettings(this.server, this.port, this.username, this.password, this.database);
}

class ServerSettingsDialog extends StatefulWidget {
  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();

  ServerSettingsDialog({super.key});
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  var usernameController = TextEditingController();
  var passwordController = TextEditingController();
  var databaseController = TextEditingController();
  var serverController = TextEditingController();
  var portController = TextEditingController();

  _ServerSettingsDialogState();

  void initController() async {
    final settings = await getServerSettings();
    serverController.text = settings.server;
    portController.text = settings.port.toStringAsFixed(0);
    usernameController.text = settings.username;
    passwordController.text = settings.password;
    databaseController.text = settings.database;
  }

  @override
  void initState() {
    super.initState();
    initController();
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    return AlertDialog(
      scrollable: true,
      title: const Text('Server ändern'),
      content: Scrollbar(
        child: Form(
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Server'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: serverController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Port'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: portController,
                enableSuggestions: false,
                keyboardType: TextInputType.number,
                maxLength: 5,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Datenbankname'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: databaseController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Benutzername'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: usernameController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: passwordController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            prefs.setString('server', serverController.text);
            prefs.setInt('port', int.parse(portController.text, radix: 10));
            prefs.setString('username', usernameController.text);
            prefs.setString('password', passwordController.text);
            prefs.setString('database', databaseController.text);
            navigator.pop();
          },
          child: const Text('Verbindung speichern'),
        ),
      ],
    );
  }
}

class AddSpoolDialog extends StatefulWidget {
  const AddSpoolDialog({super.key});

  @override
  State<AddSpoolDialog> createState() => _AddSpoolDialogState();
}

class _AddSpoolDialogState extends State<AddSpoolDialog> {
  Iterable<FilamentProfile> profiles = [];
  var weightController = TextEditingController();
  var nameController = TextEditingController();
  var costController = TextEditingController();
  FilamentProfile? profile;

  _AddSpoolDialogState();

  Future<void> loadProfiles() async {
    final settings = await getServerSettings();

    final conn = PostgreSQLConnection(
      settings.server,
      settings.port,
      settings.database,
      username: settings.username,
      password: settings.password,
    );
    await conn.open();

    try {
      List<Map<String, Map<String, dynamic>>> results = await conn.mappedResultsQuery(
          'SELECT profiles.id, profiles.vendor, profiles.material, profiles.density, profiles.diameter FROM profiles ORDER BY vendor');
      setState(() {
        profiles = results.map((e) {
          return FilamentProfile(
            e['profiles']?['id'],
            e['profiles']?['vendor'],
            e['profiles']?['material'],
            e['profiles']?['density'],
            e['profiles']?['diameter'],
          );
        });
        profile = profiles.first;
      });
    } finally {
      await conn.close();
    }
  }

  @override
  void initState() {
    super.initState();
    loadProfiles();
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return AlertDialog(
      scrollable: true,
      title: const Text('Spule hinzufügen'),
      content: Scrollbar(
        child: Form(
          child: Column(
            children: [
              DropdownButtonFormField(
                items: profiles.map((e) {
                  return DropdownMenuItem(
                    value: e.id,
                    child: Text('${e.vendor}(${e.material})'),
                  );
                }).toList(),
                onChanged: (value) => profile = profiles.firstWhere((element) => element.id == value),
                decoration: const InputDecoration(labelText: 'Hersteller und Material'),
                value: profile?.id,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: nameController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Preis in €'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: costController,
                enableSuggestions: false,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Gewicht in g'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: weightController,
                enableSuggestions: false,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () async {
            final settings = await getServerSettings();

            final conn = PostgreSQLConnection(
              settings.server,
              settings.port,
              settings.database,
              username: settings.username,
              password: settings.password,
            );
            await conn.open();

            try {
              await conn.execute(
                'INSERT INTO spools (profile_id, name, cost, weight) VALUES (@profileId, @name, @cost, @weight)',
                substitutionValues: {
                  'profileId': profile?.id,
                  'name': nameController.text,
                  'cost': double.parse(costController.text),
                  'weight': double.parse(weightController.text)
                },
              );
              navigator.pop();
            } finally {
              await conn.close();
            }
          },
          child: const Text('Spule hinzufügen'),
        ),
      ],
    );
  }
}

class EditSpoolDialog extends StatefulWidget {
  const EditSpoolDialog(this.spool, {super.key});

  final FilamentSpool spool;

  @override
  State<EditSpoolDialog> createState() => _EditSpoolDialogState(spool);
}

class _EditSpoolDialogState extends State<EditSpoolDialog> {
  final FilamentSpool spool;
  var initialWeightController = TextEditingController();
  var usedWeightController = TextEditingController();
  var nameController = TextEditingController();
  var costController = TextEditingController();

  _EditSpoolDialogState(this.spool) {
    initialWeightController.text = spool.initialWeight.toStringAsFixed(2);
    usedWeightController.text = spool.usedWeight.toStringAsFixed(2);
    nameController.text = spool.name;
    costController.text = spool.cost.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    return AlertDialog(
      scrollable: true,
      title: const Text('Spule bearbeiten'),
      content: Scrollbar(
        child: Form(
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: nameController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Preis in €'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: costController,
                enableSuggestions: false,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Ursprungsgewicht in g'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: initialWeightController,
                enableSuggestions: false,
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Verbrauchtes Gewicht in g'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: usedWeightController,
                enableSuggestions: false,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(),
          child: const Text('Änderungen verwerfen'),
        ),
        TextButton(
          onPressed: () async {
            final settings = await getServerSettings();

            final conn = PostgreSQLConnection(
              settings.server,
              settings.port,
              settings.database,
              username: settings.username,
              password: settings.password,
            );
            await conn.open();

            try {
              await conn.execute(
                'UPDATE spools SET name=@name, cost=@cost, weight=@initialWeight, used=@usedWeight WHERE name = @oldName',
                substitutionValues: {
                  'name': nameController.text,
                  'oldName': spool.name,
                  'cost': double.parse(costController.text),
                  'initialWeight': double.parse(initialWeightController.text),
                  'usedWeight': double.parse(usedWeightController.text),
                },
              );
              navigator.pop();
            } finally {
              await conn.close();
            }
          },
          child: const Text('Spule speichern'),
        ),
      ],
    );
  }
}

class AddProfileDialog extends StatefulWidget {
  const AddProfileDialog({Key? key}) : super(key: key);

  @override
  State<AddProfileDialog> createState() => _AddProfileDialogState();
}

class _AddProfileDialogState extends State<AddProfileDialog> {
  var vendorController = TextEditingController();
  var materialController = TextEditingController();
  var densityController = TextEditingController();
  var diameterController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return AlertDialog(
      scrollable: true,
      title: const Text('Profil hinzufügen'),
      content: Scrollbar(
        child: Form(
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Hersteller'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: vendorController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Material'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: materialController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Dichte in g/m³'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: densityController,
                enableSuggestions: false,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Durchmesser in mm'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: diameterController,
                enableSuggestions: false,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () async {
            final settings = await getServerSettings();

            final conn = PostgreSQLConnection(
              settings.server,
              settings.port,
              settings.database,
              username: settings.username,
              password: settings.password,
            );
            await conn.open();

            try {
              await conn.execute(
                'INSERT INTO profiles (vendor, material, density, diameter) VALUES (@vendor, @material, @density, @diameter)',
                substitutionValues: {
                  'vendor': vendorController.text,
                  'material': materialController.text,
                  'density': double.parse(densityController.text),
                  'diameter': double.parse(diameterController.text)
                },
              );
              navigator.pop();
            } finally {
              await conn.close();
            }
          },
          child: const Text('Profil hinzufügen'),
        ),
      ],
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog(this.profile, {Key? key}) : super(key: key);

  final FilamentProfile profile;

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState(profile);
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  var id = 0;
  var vendorController = TextEditingController();
  var materialController = TextEditingController();
  var densityController = TextEditingController();
  var diameterController = TextEditingController();

  _EditProfileDialogState(FilamentProfile profile) {
    id = profile.id;
    vendorController.text = profile.vendor;
    materialController.text = profile.material;
    densityController.text = profile.density.toStringAsFixed(2);
    diameterController.text = profile.diameter.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return AlertDialog(
      scrollable: true,
      title: const Text('Profil bearbeiten'),
      content: Scrollbar(
        child: Form(
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Hersteller'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: vendorController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Material'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: materialController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Dichte in g/m³'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: densityController,
                enableSuggestions: false,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Durchmesser in mm'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: diameterController,
                enableSuggestions: false,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(),
          child: const Text('Änderungen verwerfen'),
        ),
        TextButton(
          onPressed: () async {
            final settings = await getServerSettings();

            final conn = PostgreSQLConnection(
              settings.server,
              settings.port,
              settings.database,
              username: settings.username,
              password: settings.password,
            );
            await conn.open();

            try {
              await conn.execute(
                'UPDATE profiles SET vendor=@vendor, material=@material, density=@density, diameter=@diameter WHERE id=@id',
                substitutionValues: {
                  'vendor': vendorController.text,
                  'material': materialController.text,
                  'density': double.parse(densityController.text),
                  'diameter': double.parse(diameterController.text),
                  'id': id,
                },
              );
              navigator.pop();
            } finally {
              await conn.close();
            }
          },
          child: const Text('Profil speichern'),
        ),
      ],
    );
  }
}

class OverviewPage extends StatefulWidget {
  const OverviewPage({Key? key}) : super(key: key);

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  var server = '192.168.2.219';
  var port = 5432;
  var username = 'printer';
  var password = 'printer';
  var database = 'printer';
  Iterable<FilamentProfile> profiles = [];
  Iterable<FilamentSpool> spools = [];

  Future<void> deleteSpool(FilamentSpool spool) async {
    final settings = await getServerSettings();

    final conn = PostgreSQLConnection(
      settings.server,
      settings.port,
      settings.database,
      username: settings.username,
      password: settings.password,
    );
    await conn.open();

    try {
      await conn.execute('DELETE FROM spools WHERE name = @name', substitutionValues: {'name': spool.name});
      await loadSpools();
    } finally {
      await conn.close();
    }
  }

  Future<void> loadSpools() async {
    final settings = await getServerSettings();

    final conn = PostgreSQLConnection(
      settings.server,
      settings.port,
      settings.database,
      username: settings.username,
      password: settings.password,
    );
    await conn.open();

    try {
      List<Map<String, Map<String, dynamic>>> results = await conn
          .mappedResultsQuery('SELECT spools.name, spools.weight, spools.used, spools.cost FROM spools ORDER BY name');
      setState(() {
        spools = results.map((e) {
          return FilamentSpool(
              e['spools']?['weight'] ?? 0, e['spools']?['used'] ?? 0, e['spools']?['name'] ?? '', e['spools']?['cost']);
        });
      });
    } finally {
      await conn.close();
    }
  }

  Future<void> initialize() async {
    await initSharedPref();
    await loadProfiles();
    await loadSpools();
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> loadProfiles() async {
    final settings = await getServerSettings();

    final conn = PostgreSQLConnection(
      settings.server,
      settings.port,
      settings.database,
      username: settings.username,
      password: settings.password,
    );
    await conn.open();

    try {
      List<Map<String, Map<String, dynamic>>> results = await conn.mappedResultsQuery(
          'SELECT profiles.id, profiles.vendor, profiles.material, profiles.density, profiles.diameter FROM profiles ORDER BY vendor');
      setState(() {
        profiles = results.map((e) {
          return FilamentProfile(
            e['profiles']?['id'],
            e['profiles']?['vendor'],
            e['profiles']?['material'],
            e['profiles']?['density'],
            e['profiles']?['diameter'],
          );
        });
      });
    } finally {
      await conn.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Filament Manager'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Spulen'),
              Tab(text: 'Profile'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () async {
                final dialog = ServerSettingsDialog();
                await showDialog(context: context, builder: (context) => dialog);
                await loadSpools();
                await loadProfiles();
              },
              icon: const Icon(MdiIcons.databaseEdit),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            Scaffold(
              body: RefreshIndicator(
                onRefresh: () async {
                  await loadSpools();
                },
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    final spool = spools.elementAt(index);
                    return Dismissible(
                      key: Key(spool.name),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).errorColor,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Icon(
                              Icons.delete,
                              color: Theme.of(context).colorScheme.onError,
                            ),
                          ),
                        ),
                      ),
                      onDismissed: (direction) {
                        deleteSpool(spool);
                        setState(() {
                          spools = spools.where((element) => element.name != spool.name);
                        });
                      },
                      child: ListTile(
                        isThreeLine: true,
                        title: Text(spool.name),
                        subtitle: Text(
                            '${(spool.initialWeight - spool.usedWeight).toStringAsFixed(2)}g übrig\nKosten: ${spool.cost.toStringAsFixed(2)} €'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final dialog = EditSpoolDialog(spool);
                            await showDialog(
                              context: context,
                              builder: (context) => dialog,
                            );
                            await loadSpools();
                          },
                        ),
                      ),
                    );
                  },
                  itemCount: spools.length,
                ),
              ),
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () async {
                  const dialog = AddSpoolDialog();
                  await showDialog(
                    context: context,
                    builder: (context) => dialog,
                  );
                  await loadSpools();
                },
              ),
            ),
            Scaffold(
              body: RefreshIndicator(
                onRefresh: () async {
                  await loadProfiles();
                },
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    final profile = profiles.elementAt(index);
                    return ListTile(
                      isThreeLine: true,
                      title: Text('${profile.vendor} ${profile.material}'),
                      subtitle: Text(
                          'Dichte: ${(profile.density).toStringAsFixed(2)}g/m³\nDurchmesser: ${profile.diameter.toStringAsFixed(2)} €'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final dialog = EditProfileDialog(profile);
                          await showDialog(
                            context: context,
                            builder: (context) => dialog,
                          );
                          await loadProfiles();
                        },
                      ),
                    );
                  },
                  itemCount: profiles.length,
                ),
              ),
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () async {
                  const dialog = AddProfileDialog();
                  await showDialog(
                    context: context,
                    builder: (context) => dialog,
                  );
                  await loadProfiles();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
