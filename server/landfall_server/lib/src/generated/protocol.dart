/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i3;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i4;
import 'agent/api_key.dart' as _i5;
import 'agent/api_key_create_response.dart' as _i6;
import 'agent/landfall_exception.dart' as _i7;
import 'auth/otp_account.dart' as _i8;
import 'auth/otp_request.dart' as _i9;
import 'calendar/calendar_event.dart' as _i10;
import 'calendar/linked_credential.dart' as _i11;
import 'cards/card_push_request.dart' as _i12;
import 'cards/card_row.dart' as _i13;
import 'companion/companion_action.dart' as _i14;
import 'companion/companion_entity.dart' as _i15;
import 'greetings/greeting.dart' as _i16;
import 'layout/layout_config.dart' as _i17;
import 'license/integration_pack.dart' as _i18;
import 'license/license_key.dart' as _i19;
import 'license/license_status_response.dart' as _i20;
import 'license/owned_pack.dart' as _i21;
import 'license/pack_info_response.dart' as _i22;
import 'photo/photo.dart' as _i23;
import 'profile/dashboard_profile.dart' as _i24;
import 'settings/linked_credential_summary.dart' as _i25;
import 'settings/remote_display_settings.dart' as _i26;
import 'theme/landfall_theme.dart' as _i27;
import 'theme/marketplace_theme_info.dart' as _i28;
import 'theme/theme_purchase.dart' as _i29;
import 'theme/theme_upload_result.dart' as _i30;
import 'theme/theme_validation_error.dart' as _i31;
import 'weather/weather_current.dart' as _i32;
import 'weather/weather_forecast.dart' as _i33;
import 'package:landfall_server/src/generated/cards/card_row.dart' as _i34;
import 'package:landfall_server/src/generated/agent/api_key.dart' as _i35;
import 'dart:typed_data' as _i36;
import 'package:landfall_server/src/generated/calendar/calendar_event.dart'
    as _i37;
import 'package:landfall_server/src/generated/layout/layout_config.dart'
    as _i38;
import 'package:landfall_server/src/generated/license/pack_info_response.dart'
    as _i39;
import 'package:landfall_server/src/generated/photo/photo.dart' as _i40;
import 'package:landfall_server/src/generated/profile/dashboard_profile.dart'
    as _i41;
import 'package:landfall_server/src/generated/settings/linked_credential_summary.dart'
    as _i42;
import 'package:landfall_server/src/generated/theme/marketplace_theme_info.dart'
    as _i43;
import 'package:landfall_server/src/generated/theme/landfall_theme.dart'
    as _i44;
import 'package:landfall_server/src/generated/weather/weather_forecast.dart'
    as _i45;
export 'agent/api_key.dart';
export 'agent/api_key_create_response.dart';
export 'agent/landfall_exception.dart';
export 'auth/otp_account.dart';
export 'auth/otp_request.dart';
export 'calendar/calendar_event.dart';
export 'calendar/linked_credential.dart';
export 'cards/card_push_request.dart';
export 'cards/card_row.dart';
export 'companion/companion_action.dart';
export 'companion/companion_entity.dart';
export 'greetings/greeting.dart';
export 'layout/layout_config.dart';
export 'license/integration_pack.dart';
export 'license/license_key.dart';
export 'license/license_status_response.dart';
export 'license/owned_pack.dart';
export 'license/pack_info_response.dart';
export 'photo/photo.dart';
export 'profile/dashboard_profile.dart';
export 'settings/linked_credential_summary.dart';
export 'settings/remote_display_settings.dart';
export 'theme/landfall_theme.dart';
export 'theme/marketplace_theme_info.dart';
export 'theme/theme_purchase.dart';
export 'theme/theme_upload_result.dart';
export 'theme/theme_validation_error.dart';
export 'weather/weather_current.dart';
export 'weather/weather_forecast.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'api_keys',
      dartName: 'ApiKey',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'api_keys_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'keyHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'prefix',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'lastUsedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'lastUsedIp',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'revokedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'dailyLimit',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '500',
        ),
        _i2.ColumnDefinition(
          name: 'usageCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'usageResetAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'api_keys_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'api_keys_hash_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'keyHash',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'api_keys_revoked_at_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'revokedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'calendar_events',
      dartName: 'CalendarEvent',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'calendar_events_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'credentialId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'calendarId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'calendarName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'externalEventId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'title',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'startTime',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'endTime',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'isAllDay',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'location',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'fetchedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'calendar_events_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'calendar_events_credential_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'credentialId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'calendar_events_start_time_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'startTime',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'calendar_events_external_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'credentialId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'externalEventId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'calendar_linked_credentials',
      dartName: 'LinkedCredential',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault:
              'nextval(\'calendar_linked_credentials_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'provider',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'providerEmail',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'accessToken',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'refreshToken',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'tokenExpiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'scopes',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'calendar_linked_credentials_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'calendar_linked_credentials_auth_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'calendar_linked_credentials_provider_email_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'provider',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'providerEmail',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'calendar_linked_credentials_active_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'isActive',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'cards',
      dartName: 'CardRow',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'cards_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'externalId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'source',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'title',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'body',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'dataJson',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'actionsJson',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'layout',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'medium\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'priority',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'normal\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'expiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'persistent',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'dismissedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'cards_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'cards_external_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'externalId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'cards_dismissed_at_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'dismissedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'cards_expires_at_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'cards_created_at_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'companion_entities',
      dartName: 'CompanionEntity',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'companion_entities_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'displayId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'seed',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'rarityTier',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'speciesId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'traits',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'evolutionStage',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'assetCredit',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'lastEvolutionAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'companion_entities_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'companion_entities_display_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'displayId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'dashboard_profiles',
      dartName: 'DashboardProfile',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'dashboard_profiles_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'slug',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'themeId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'cardFilterJson',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'{}\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'scheduleJson',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'sortOrder',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'columnsCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '12',
        ),
        _i2.ColumnDefinition(
          name: 'rowsCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '8',
        ),
        _i2.ColumnDefinition(
          name: 'cardsJson',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'dashboard_profiles_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'dashboard_profiles_slug_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'slug',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'dashboard_profiles_active_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'isActive',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'dashboard_profiles_sort_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'sortOrder',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'integration_packs',
      dartName: 'IntegrationPack',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'integration_packs_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'packId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'version',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'priceUsd',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _i2.ColumnDefinition(
          name: 'authorName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'iconUrl',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'stripePaymentLink',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'integration_packs_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'integration_packs_pack_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'packId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'landfall_otp_accounts',
      dartName: 'OtpAccount',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'landfall_otp_accounts_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'email',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'landfall_otp_accounts_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'landfall_otp_accounts_email_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'email',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'landfall_otp_accounts_auth_user_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'landfall_otp_requests',
      dartName: 'OtpRequest',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'landfall_otp_requests_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'email',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'codeHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'expiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'usedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'landfall_otp_requests_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'landfall_otp_requests_email_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'email',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'landfall_otp_requests_expires_at_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'layout_configs',
      dartName: 'LayoutConfig',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'layout_configs_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'presetType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'custom\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'columnsCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '12',
        ),
        _i2.ColumnDefinition(
          name: 'rowsCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '8',
        ),
        _i2.ColumnDefinition(
          name: 'cardsJson',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'layout_configs_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'layout_configs_preset_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'presetType',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'layout_configs_active_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'isActive',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'license_keys',
      dartName: 'LicenseKey',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'license_keys_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'key',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'tier',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'activatedByUserId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'activatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'purchasedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'stripeSessionId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'buyerEmail',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'license_keys_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'license_keys_key_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'key',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'license_keys_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'activatedByUserId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'owned_packs',
      dartName: 'OwnedPack',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'owned_packs_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'packId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'grantedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'stripeSessionId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'owned_packs_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'owned_packs_user_pack_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'packId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'owned_packs_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'photos',
      dartName: 'Photo',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'photos_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'credentialId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'providerFileId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'filename',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'mimeType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'fetchedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'photos_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'photos_credential_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'credentialId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'photos_provider_file_id_uniq',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'providerFileId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'remote_display_settings',
      dartName: 'RemoteDisplaySettings',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault:
              'nextval(\'remote_display_settings_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'displayId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'dimEnabled',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'dimStartHour',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '22',
        ),
        _i2.ColumnDefinition(
          name: 'dimEndHour',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '7',
        ),
        _i2.ColumnDefinition(
          name: 'dimLevel',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '0.85',
        ),
        _i2.ColumnDefinition(
          name: 'locationName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'photoSourceJson',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'remote_display_settings_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'remote_display_settings_display_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'displayId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'theme_purchases',
      dartName: 'ThemePurchase',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'theme_purchases_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'themeId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'purchasedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'stripePaymentIntentId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'theme_purchases_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'theme_purchases_user_theme_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'themeId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'theme_purchases_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'theme_purchases_stripe_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'stripePaymentIntentId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'themes',
      dartName: 'LandfallTheme',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'themes_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'slug',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'schemaVersion',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'author',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'previewUrl',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'tagsJson',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'[]\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'tokensJson',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'resolvedJson',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'isBuiltIn',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'isMarketplace',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'priceUsd',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'stripeProductId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'themes_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'themes_slug_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'slug',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'themes_builtin_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'isBuiltIn',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'themes_marketplace_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'isMarketplace',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'weather_current',
      dartName: 'WeatherCurrent',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'weather_current_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'locationName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'tempC',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _i2.ColumnDefinition(
          name: 'feelsLikeC',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _i2.ColumnDefinition(
          name: 'condition',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'iconCode',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'humidity',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'windSpeedMs',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _i2.ColumnDefinition(
          name: 'fetchedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'weather_current_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'weather_forecasts',
      dartName: 'WeatherForecast',
      schema: 'public',
      module: 'landfall',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'weather_forecasts_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'locationName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'forecastDate',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'minTempC',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _i2.ColumnDefinition(
          name: 'maxTempC',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _i2.ColumnDefinition(
          name: 'condition',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'iconCode',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'fetchedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'weather_forecasts_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'weather_forecasts_date_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'forecastDate',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i5.ApiKey) {
      return _i5.ApiKey.fromJson(data) as T;
    }
    if (t == _i6.ApiKeyCreateResponse) {
      return _i6.ApiKeyCreateResponse.fromJson(data) as T;
    }
    if (t == _i7.LandfallException) {
      return _i7.LandfallException.fromJson(data) as T;
    }
    if (t == _i8.OtpAccount) {
      return _i8.OtpAccount.fromJson(data) as T;
    }
    if (t == _i9.OtpRequest) {
      return _i9.OtpRequest.fromJson(data) as T;
    }
    if (t == _i10.CalendarEvent) {
      return _i10.CalendarEvent.fromJson(data) as T;
    }
    if (t == _i11.LinkedCredential) {
      return _i11.LinkedCredential.fromJson(data) as T;
    }
    if (t == _i12.CardPushRequest) {
      return _i12.CardPushRequest.fromJson(data) as T;
    }
    if (t == _i13.CardRow) {
      return _i13.CardRow.fromJson(data) as T;
    }
    if (t == _i14.CompanionAction) {
      return _i14.CompanionAction.fromJson(data) as T;
    }
    if (t == _i15.CompanionEntity) {
      return _i15.CompanionEntity.fromJson(data) as T;
    }
    if (t == _i16.Greeting) {
      return _i16.Greeting.fromJson(data) as T;
    }
    if (t == _i17.LayoutConfig) {
      return _i17.LayoutConfig.fromJson(data) as T;
    }
    if (t == _i18.IntegrationPack) {
      return _i18.IntegrationPack.fromJson(data) as T;
    }
    if (t == _i19.LicenseKey) {
      return _i19.LicenseKey.fromJson(data) as T;
    }
    if (t == _i20.LicenseStatusResponse) {
      return _i20.LicenseStatusResponse.fromJson(data) as T;
    }
    if (t == _i21.OwnedPack) {
      return _i21.OwnedPack.fromJson(data) as T;
    }
    if (t == _i22.PackInfoResponse) {
      return _i22.PackInfoResponse.fromJson(data) as T;
    }
    if (t == _i23.Photo) {
      return _i23.Photo.fromJson(data) as T;
    }
    if (t == _i24.DashboardProfile) {
      return _i24.DashboardProfile.fromJson(data) as T;
    }
    if (t == _i25.LinkedCredentialSummary) {
      return _i25.LinkedCredentialSummary.fromJson(data) as T;
    }
    if (t == _i26.RemoteDisplaySettings) {
      return _i26.RemoteDisplaySettings.fromJson(data) as T;
    }
    if (t == _i27.LandfallTheme) {
      return _i27.LandfallTheme.fromJson(data) as T;
    }
    if (t == _i28.MarketplaceThemeInfo) {
      return _i28.MarketplaceThemeInfo.fromJson(data) as T;
    }
    if (t == _i29.ThemePurchase) {
      return _i29.ThemePurchase.fromJson(data) as T;
    }
    if (t == _i30.ThemeUploadResult) {
      return _i30.ThemeUploadResult.fromJson(data) as T;
    }
    if (t == _i31.ThemeValidationError) {
      return _i31.ThemeValidationError.fromJson(data) as T;
    }
    if (t == _i32.WeatherCurrent) {
      return _i32.WeatherCurrent.fromJson(data) as T;
    }
    if (t == _i33.WeatherForecast) {
      return _i33.WeatherForecast.fromJson(data) as T;
    }
    if (t == _i1.getType<_i5.ApiKey?>()) {
      return (data != null ? _i5.ApiKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.ApiKeyCreateResponse?>()) {
      return (data != null ? _i6.ApiKeyCreateResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.LandfallException?>()) {
      return (data != null ? _i7.LandfallException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.OtpAccount?>()) {
      return (data != null ? _i8.OtpAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.OtpRequest?>()) {
      return (data != null ? _i9.OtpRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.CalendarEvent?>()) {
      return (data != null ? _i10.CalendarEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.LinkedCredential?>()) {
      return (data != null ? _i11.LinkedCredential.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.CardPushRequest?>()) {
      return (data != null ? _i12.CardPushRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.CardRow?>()) {
      return (data != null ? _i13.CardRow.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.CompanionAction?>()) {
      return (data != null ? _i14.CompanionAction.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.CompanionEntity?>()) {
      return (data != null ? _i15.CompanionEntity.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.Greeting?>()) {
      return (data != null ? _i16.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.LayoutConfig?>()) {
      return (data != null ? _i17.LayoutConfig.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.IntegrationPack?>()) {
      return (data != null ? _i18.IntegrationPack.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.LicenseKey?>()) {
      return (data != null ? _i19.LicenseKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.LicenseStatusResponse?>()) {
      return (data != null ? _i20.LicenseStatusResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i21.OwnedPack?>()) {
      return (data != null ? _i21.OwnedPack.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.PackInfoResponse?>()) {
      return (data != null ? _i22.PackInfoResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.Photo?>()) {
      return (data != null ? _i23.Photo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.DashboardProfile?>()) {
      return (data != null ? _i24.DashboardProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.LinkedCredentialSummary?>()) {
      return (data != null ? _i25.LinkedCredentialSummary.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i26.RemoteDisplaySettings?>()) {
      return (data != null ? _i26.RemoteDisplaySettings.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i27.LandfallTheme?>()) {
      return (data != null ? _i27.LandfallTheme.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.MarketplaceThemeInfo?>()) {
      return (data != null ? _i28.MarketplaceThemeInfo.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i29.ThemePurchase?>()) {
      return (data != null ? _i29.ThemePurchase.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.ThemeUploadResult?>()) {
      return (data != null ? _i30.ThemeUploadResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.ThemeValidationError?>()) {
      return (data != null ? _i31.ThemeValidationError.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i32.WeatherCurrent?>()) {
      return (data != null ? _i32.WeatherCurrent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i33.WeatherForecast?>()) {
      return (data != null ? _i33.WeatherForecast.fromJson(data) : null) as T;
    }
    if (t == List<_i31.ThemeValidationError>) {
      return (data as List)
              .map((e) => deserialize<_i31.ThemeValidationError>(e))
              .toList()
          as T;
    }
    if (t == List<_i34.CardRow>) {
      return (data as List).map((e) => deserialize<_i34.CardRow>(e)).toList()
          as T;
    }
    if (t == List<_i35.ApiKey>) {
      return (data as List).map((e) => deserialize<_i35.ApiKey>(e)).toList()
          as T;
    }
    if (t == _i1.getType<({_i36.ByteData challenge, _i1.UuidValue id})>()) {
      return (
            challenge: deserialize<_i36.ByteData>(
              ((data as Map)['n'] as Map)['challenge'],
            ),
            id: deserialize<_i1.UuidValue>(data['n']['id']),
          )
          as T;
    }
    if (t == List<_i37.CalendarEvent>) {
      return (data as List)
              .map((e) => deserialize<_i37.CalendarEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i38.LayoutConfig>) {
      return (data as List)
              .map((e) => deserialize<_i38.LayoutConfig>(e))
              .toList()
          as T;
    }
    if (t == List<_i39.PackInfoResponse>) {
      return (data as List)
              .map((e) => deserialize<_i39.PackInfoResponse>(e))
              .toList()
          as T;
    }
    if (t == List<_i40.Photo>) {
      return (data as List).map((e) => deserialize<_i40.Photo>(e)).toList()
          as T;
    }
    if (t == List<_i41.DashboardProfile>) {
      return (data as List)
              .map((e) => deserialize<_i41.DashboardProfile>(e))
              .toList()
          as T;
    }
    if (t == List<_i42.LinkedCredentialSummary>) {
      return (data as List)
              .map((e) => deserialize<_i42.LinkedCredentialSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i43.MarketplaceThemeInfo>) {
      return (data as List)
              .map((e) => deserialize<_i43.MarketplaceThemeInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i44.LandfallTheme>) {
      return (data as List)
              .map((e) => deserialize<_i44.LandfallTheme>(e))
              .toList()
          as T;
    }
    if (t == List<_i45.WeatherForecast>) {
      return (data as List)
              .map((e) => deserialize<_i45.WeatherForecast>(e))
              .toList()
          as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i5.ApiKey => 'ApiKey',
      _i6.ApiKeyCreateResponse => 'ApiKeyCreateResponse',
      _i7.LandfallException => 'LandfallException',
      _i8.OtpAccount => 'OtpAccount',
      _i9.OtpRequest => 'OtpRequest',
      _i10.CalendarEvent => 'CalendarEvent',
      _i11.LinkedCredential => 'LinkedCredential',
      _i12.CardPushRequest => 'CardPushRequest',
      _i13.CardRow => 'CardRow',
      _i14.CompanionAction => 'CompanionAction',
      _i15.CompanionEntity => 'CompanionEntity',
      _i16.Greeting => 'Greeting',
      _i17.LayoutConfig => 'LayoutConfig',
      _i18.IntegrationPack => 'IntegrationPack',
      _i19.LicenseKey => 'LicenseKey',
      _i20.LicenseStatusResponse => 'LicenseStatusResponse',
      _i21.OwnedPack => 'OwnedPack',
      _i22.PackInfoResponse => 'PackInfoResponse',
      _i23.Photo => 'Photo',
      _i24.DashboardProfile => 'DashboardProfile',
      _i25.LinkedCredentialSummary => 'LinkedCredentialSummary',
      _i26.RemoteDisplaySettings => 'RemoteDisplaySettings',
      _i27.LandfallTheme => 'LandfallTheme',
      _i28.MarketplaceThemeInfo => 'MarketplaceThemeInfo',
      _i29.ThemePurchase => 'ThemePurchase',
      _i30.ThemeUploadResult => 'ThemeUploadResult',
      _i31.ThemeValidationError => 'ThemeValidationError',
      _i32.WeatherCurrent => 'WeatherCurrent',
      _i33.WeatherForecast => 'WeatherForecast',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('landfall.', '');
    }

    switch (data) {
      case _i5.ApiKey():
        return 'ApiKey';
      case _i6.ApiKeyCreateResponse():
        return 'ApiKeyCreateResponse';
      case _i7.LandfallException():
        return 'LandfallException';
      case _i8.OtpAccount():
        return 'OtpAccount';
      case _i9.OtpRequest():
        return 'OtpRequest';
      case _i10.CalendarEvent():
        return 'CalendarEvent';
      case _i11.LinkedCredential():
        return 'LinkedCredential';
      case _i12.CardPushRequest():
        return 'CardPushRequest';
      case _i13.CardRow():
        return 'CardRow';
      case _i14.CompanionAction():
        return 'CompanionAction';
      case _i15.CompanionEntity():
        return 'CompanionEntity';
      case _i16.Greeting():
        return 'Greeting';
      case _i17.LayoutConfig():
        return 'LayoutConfig';
      case _i18.IntegrationPack():
        return 'IntegrationPack';
      case _i19.LicenseKey():
        return 'LicenseKey';
      case _i20.LicenseStatusResponse():
        return 'LicenseStatusResponse';
      case _i21.OwnedPack():
        return 'OwnedPack';
      case _i22.PackInfoResponse():
        return 'PackInfoResponse';
      case _i23.Photo():
        return 'Photo';
      case _i24.DashboardProfile():
        return 'DashboardProfile';
      case _i25.LinkedCredentialSummary():
        return 'LinkedCredentialSummary';
      case _i26.RemoteDisplaySettings():
        return 'RemoteDisplaySettings';
      case _i27.LandfallTheme():
        return 'LandfallTheme';
      case _i28.MarketplaceThemeInfo():
        return 'MarketplaceThemeInfo';
      case _i29.ThemePurchase():
        return 'ThemePurchase';
      case _i30.ThemeUploadResult():
        return 'ThemeUploadResult';
      case _i31.ThemeValidationError():
        return 'ThemeValidationError';
      case _i32.WeatherCurrent():
        return 'WeatherCurrent';
      case _i33.WeatherForecast():
        return 'WeatherForecast';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'ApiKey') {
      return deserialize<_i5.ApiKey>(data['data']);
    }
    if (dataClassName == 'ApiKeyCreateResponse') {
      return deserialize<_i6.ApiKeyCreateResponse>(data['data']);
    }
    if (dataClassName == 'LandfallException') {
      return deserialize<_i7.LandfallException>(data['data']);
    }
    if (dataClassName == 'OtpAccount') {
      return deserialize<_i8.OtpAccount>(data['data']);
    }
    if (dataClassName == 'OtpRequest') {
      return deserialize<_i9.OtpRequest>(data['data']);
    }
    if (dataClassName == 'CalendarEvent') {
      return deserialize<_i10.CalendarEvent>(data['data']);
    }
    if (dataClassName == 'LinkedCredential') {
      return deserialize<_i11.LinkedCredential>(data['data']);
    }
    if (dataClassName == 'CardPushRequest') {
      return deserialize<_i12.CardPushRequest>(data['data']);
    }
    if (dataClassName == 'CardRow') {
      return deserialize<_i13.CardRow>(data['data']);
    }
    if (dataClassName == 'CompanionAction') {
      return deserialize<_i14.CompanionAction>(data['data']);
    }
    if (dataClassName == 'CompanionEntity') {
      return deserialize<_i15.CompanionEntity>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i16.Greeting>(data['data']);
    }
    if (dataClassName == 'LayoutConfig') {
      return deserialize<_i17.LayoutConfig>(data['data']);
    }
    if (dataClassName == 'IntegrationPack') {
      return deserialize<_i18.IntegrationPack>(data['data']);
    }
    if (dataClassName == 'LicenseKey') {
      return deserialize<_i19.LicenseKey>(data['data']);
    }
    if (dataClassName == 'LicenseStatusResponse') {
      return deserialize<_i20.LicenseStatusResponse>(data['data']);
    }
    if (dataClassName == 'OwnedPack') {
      return deserialize<_i21.OwnedPack>(data['data']);
    }
    if (dataClassName == 'PackInfoResponse') {
      return deserialize<_i22.PackInfoResponse>(data['data']);
    }
    if (dataClassName == 'Photo') {
      return deserialize<_i23.Photo>(data['data']);
    }
    if (dataClassName == 'DashboardProfile') {
      return deserialize<_i24.DashboardProfile>(data['data']);
    }
    if (dataClassName == 'LinkedCredentialSummary') {
      return deserialize<_i25.LinkedCredentialSummary>(data['data']);
    }
    if (dataClassName == 'RemoteDisplaySettings') {
      return deserialize<_i26.RemoteDisplaySettings>(data['data']);
    }
    if (dataClassName == 'LandfallTheme') {
      return deserialize<_i27.LandfallTheme>(data['data']);
    }
    if (dataClassName == 'MarketplaceThemeInfo') {
      return deserialize<_i28.MarketplaceThemeInfo>(data['data']);
    }
    if (dataClassName == 'ThemePurchase') {
      return deserialize<_i29.ThemePurchase>(data['data']);
    }
    if (dataClassName == 'ThemeUploadResult') {
      return deserialize<_i30.ThemeUploadResult>(data['data']);
    }
    if (dataClassName == 'ThemeValidationError') {
      return deserialize<_i31.ThemeValidationError>(data['data']);
    }
    if (dataClassName == 'WeatherCurrent') {
      return deserialize<_i32.WeatherCurrent>(data['data']);
    }
    if (dataClassName == 'WeatherForecast') {
      return deserialize<_i33.WeatherForecast>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i4.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i5.ApiKey:
        return _i5.ApiKey.t;
      case _i8.OtpAccount:
        return _i8.OtpAccount.t;
      case _i9.OtpRequest:
        return _i9.OtpRequest.t;
      case _i10.CalendarEvent:
        return _i10.CalendarEvent.t;
      case _i11.LinkedCredential:
        return _i11.LinkedCredential.t;
      case _i13.CardRow:
        return _i13.CardRow.t;
      case _i15.CompanionEntity:
        return _i15.CompanionEntity.t;
      case _i17.LayoutConfig:
        return _i17.LayoutConfig.t;
      case _i18.IntegrationPack:
        return _i18.IntegrationPack.t;
      case _i19.LicenseKey:
        return _i19.LicenseKey.t;
      case _i21.OwnedPack:
        return _i21.OwnedPack.t;
      case _i23.Photo:
        return _i23.Photo.t;
      case _i24.DashboardProfile:
        return _i24.DashboardProfile.t;
      case _i26.RemoteDisplaySettings:
        return _i26.RemoteDisplaySettings.t;
      case _i27.LandfallTheme:
        return _i27.LandfallTheme.t;
      case _i29.ThemePurchase:
        return _i29.ThemePurchase.t;
      case _i32.WeatherCurrent:
        return _i32.WeatherCurrent.t;
      case _i33.WeatherForecast:
        return _i33.WeatherForecast.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'landfall';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    if (record is ({_i36.ByteData challenge, _i1.UuidValue id})) {
      return {
        "n": {
          "challenge": record.challenge.toJson(),
          "id": record.id.toJson(),
        },
      };
    }
    try {
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i4.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }

  /// Maps container types (like [List], [Map], [Set]) containing
  /// [Record]s or non-String-keyed [Map]s to their JSON representation.
  ///
  /// It should not be called for [SerializableModel] types. These
  /// handle the "[Record] in container" mapping internally already.
  ///
  /// It is only supposed to be called from generated protocol code.
  ///
  /// Returns either a `List<dynamic>` (for List, Sets, and Maps with
  /// non-String keys) or a `Map<String, dynamic>` in case the input was
  /// a `Map<String, …>`.
  Object? mapContainerToJson(Object obj) {
    if (obj is! Iterable && obj is! Map) {
      throw ArgumentError.value(
        obj,
        'obj',
        'The object to serialize should be of type List, Map, or Set',
      );
    }

    dynamic mapIfNeeded(Object? obj) {
      return switch (obj) {
        Record record => mapRecordToJson(record),
        Iterable iterable => mapContainerToJson(iterable),
        Map map => mapContainerToJson(map),
        Object? value => value,
      };
    }

    switch (obj) {
      case Map<String, dynamic>():
        return {
          for (var entry in obj.entries) entry.key: mapIfNeeded(entry.value),
        };
      case Map():
        return [
          for (var entry in obj.entries)
            {
              'k': mapIfNeeded(entry.key),
              'v': mapIfNeeded(entry.value),
            },
        ];

      case Iterable():
        return [
          for (var e in obj) mapIfNeeded(e),
        ];
    }

    return obj;
  }
}
