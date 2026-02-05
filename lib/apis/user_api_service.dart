import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:klarto/config.dart';
import 'package:path/path.dart' as p;

class UserApiService {
	static final String _baseUrl = AppConfig.baseUrl;

	Future<Map<String, String>> _getHeaders() async {
		final prefs = await SharedPreferences.getInstance();
		final token = prefs.getString('jwt_token');
		return {
			'Authorization': 'Bearer $token',
			'Content-Type': 'application/json',
		};
	}

	Future<Map<String, dynamic>> updateProfile({required String name}) async {
		final url = Uri.parse('$_baseUrl/profile');
		final headers = await _getHeaders();
		try {
			final response = await http.put(url, headers: headers, body: json.encode({'name': name}));
			final responseBody = json.decode(response.body);
			if (response.statusCode == 200) return {'success': true, 'message': responseBody['message']};
			return {'success': false, 'message': responseBody['message'] ?? 'Failed to update profile'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> createTeam(String name, List<String> memberEmails) async {
		final url = Uri.parse('$_baseUrl/teams');
		final headers = await _getHeaders();
		try {
			final response = await http.post(
				url,
				headers: headers,
				body: json.encode({'name': name, 'members': memberEmails}),
			);
			final body = json.decode(response.body);
			if (response.statusCode == 200) return {'success': true, 'name': body['name']};
			return {'success': false, 'message': body['message'] ?? 'Failed to create team'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> uploadAvatar({Uint8List? bytes, String? fileName}) async {
		final url = Uri.parse('$_baseUrl/profile/avatar');
		final headers = await _getHeaders();
		if (bytes == null || bytes.isEmpty) return {'success': false, 'message': 'No image bytes provided.'};
		try {
			final ext = (fileName != null) ? p.extension(fileName).toLowerCase() : '.png';
			String subtype = 'png';
			if (ext == '.jpg' || ext == '.jpeg') subtype = 'jpeg';
			else if (ext == '.gif') subtype = 'gif';
			else if (ext == '.webp') subtype = 'webp';
			final mime = 'image/$subtype';
			final base64Str = base64Encode(bytes);
			final dataUri = 'data:$mime;base64,$base64Str';
			final response = await http.post(url, headers: headers, body: json.encode({'avatar_base64': dataUri}));
			final responseBody = json.decode(response.body);
			if (response.statusCode == 200) {
				return {
					'success': true,
					'message': responseBody['message'],
					'profile_picture_base64': responseBody['profile_picture_base64'],
				};
			}
			return {'success': false, 'message': responseBody['message'] ?? 'Failed to upload avatar'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> inviteTeam(List<String> emails) async {
		final url = Uri.parse('$_baseUrl/team/invite');
		final headers = await _getHeaders();
		try {
			final response = await http.post(url, headers: headers, body: json.encode({'emails': emails}));
			final body = json.decode(response.body);
			if (response.statusCode == 200) return {'success': true, 'results': body['results']};
			return {'success': false, 'message': body['message'] ?? 'Failed to invite'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> getInvitedMembers() async {
		final url = Uri.parse('$_baseUrl/team/invited');
		final headers = await _getHeaders();
		try {
			final response = await http.get(url, headers: headers);
			if (response.statusCode == 200) {
				final body = json.decode(response.body);
				return {'success': true, 'invited': body};
			}
			final body = json.decode(response.body);
			return {'success': false, 'message': body['message'] ?? 'Failed to fetch invited members'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> getAllMembers() async {
		final url = Uri.parse('$_baseUrl/users');
		final headers = await _getHeaders();
		try {
			final response = await http.get(url, headers: headers);
			if (response.statusCode == 200) {
				final body = json.decode(response.body);
				return {'success': true, 'users': body};
			}
			final body = json.decode(response.body);
			return {'success': false, 'message': body['message'] ?? 'Failed to fetch users'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> getTeamMembers() async {
		final url = Uri.parse('$_baseUrl/team/members');
		final headers = await _getHeaders();
		try {
			final response = await http.get(url, headers: headers);
			if (response.statusCode == 200) {
				final body = json.decode(response.body);
				return {'success': true, 'members': body};
			}
			final body = json.decode(response.body);
			return {'success': false, 'message': body['message'] ?? 'Failed to fetch team members'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> addMemberToTeam(String email, {String? teamName}) async {
		final url = Uri.parse('$_baseUrl/team/add-member');
		final headers = await _getHeaders();
		try {
			final body = {'email': email};
			if (teamName != null && teamName.trim().isNotEmpty) body['team_name'] = teamName.trim();
			final response = await http.post(url, headers: headers, body: json.encode(body));
			final respBody = json.decode(response.body);
			if (response.statusCode == 200) return {'success': true, 'member': respBody['member'], 'alreadyMember': respBody['alreadyMember'] == true};
			return {'success': false, 'message': respBody['message'] ?? 'Failed to add member'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> getProfile() async {
		final url = Uri.parse('$_baseUrl/profile');
		final headers = await _getHeaders();
		try {
			final response = await http.get(url, headers: headers);
			final body = json.decode(response.body);
			if (response.statusCode == 200) {
				return {
					'success': true,
					'name': body['name'],
					'email': body['email'],
					'profile_picture_base64': body['profile_picture_base64'],
					'has_completed_onboarding': body['has_completed_onboarding'] == true,
				};
			}
			return {'success': false, 'message': body['message'] ?? 'Failed to fetch profile'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> completeOnboarding() async {
		final url = Uri.parse('$_baseUrl/complete-onboarding');
		final headers = await _getHeaders();
		try {
			final response = await http.post(url, headers: headers);
			if (response.statusCode == 200) {
				return {'success': true};
			}
			final body = json.decode(response.body);
			return {'success': false, 'message': body['message'] ?? 'Failed to complete onboarding'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> getTeams() async {
		final url = Uri.parse('$_baseUrl/teams');
		final headers = await _getHeaders();
		try {
			final response = await http.get(url, headers: headers);
			if (response.statusCode == 200) {
				final body = json.decode(response.body);
				return {'success': true, 'teams': body};
			}
			final body = json.decode(response.body);
			return {'success': false, 'message': body['message'] ?? 'Failed to fetch teams'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<List<dynamic>> getSubscriptionPlans() async {
		final url = Uri.parse('$_baseUrl/plans');
		try {
			final response = await http.get(url);
			if (response.statusCode == 200) {
				return json.decode(response.body) as List<dynamic>;
			}
			return [];
		} catch (e) {
			return [];
		}
	}

	Future<Map<String, dynamic>> subscribe({required String planId, required String paymentMethodId, bool isTrial = false}) async {
		final url = Uri.parse('$_baseUrl/subscribe');
		final headers = await _getHeaders();
		try {
			final response = await http.post(
				url,
				headers: headers,
				body: json.encode({
					'plan_id': planId,
					'payment_method_id': paymentMethodId,
					'is_trial': isTrial,
				}),
			);
			final body = json.decode(response.body);
			if (response.statusCode == 200) return {'success': true};
			return {'success': false, 'message': body['message'] ?? 'Subscription failed'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>?> getCurrentSubscription() async {
		final url = Uri.parse('$_baseUrl/subscription');
		final headers = await _getHeaders();
		try {
			final response = await http.get(url, headers: headers);
			if (response.statusCode == 200) {
				return json.decode(response.body) as Map<String, dynamic>?;
			}
			return null;
		} catch (e) {
			return null;
		}
	}

	Future<bool> isMemberOfInviterTeam(String email) async {
		final url = Uri.parse('$_baseUrl/team/check-member');
		final headers = await _getHeaders();
		try {
			final response = await http.post(url, headers: headers, body: json.encode({'email': email}));
			if (response.statusCode == 200) {
				final body = json.decode(response.body);
				return body['is_member'] == true;
			}
			return false;
		} catch (e) {
			return false;
		}
	}

	Future<Map<String, dynamic>> setPasswordForInvite({required String token, required String password}) async {
		final url = Uri.parse('$_baseUrl/team/invite/set-password');
		try {
			final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode({'token': token, 'password': password}));
			final body = json.decode(response.body);
			if (response.statusCode == 200) return {'success': true, 'token': body['token']};
			return {'success': false, 'message': body['message'] ?? 'Failed to set password for invite'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> getProjects() async {
		final url = Uri.parse('$_baseUrl/projects');
		final headers = await _getHeaders();
		try {
			final response = await http.get(url, headers: headers);
			if (response.statusCode == 200) {
				final body = json.decode(response.body);
				return {'success': true, 'projects': body};
			}
			final body = json.decode(response.body);
			return {'success': false, 'message': body['message'] ?? 'Failed to fetch projects'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> createProject({
		required String name,
		required String color,
		required String access,
		required bool isFavorite,
	}) async {
		final url = Uri.parse('$_baseUrl/projects');
		final headers = await _getHeaders();
		try {
			final response = await http.post(
				url,
				headers: headers,
				body: json.encode({
					'name': name,
					'color': color,
					'access': access,
					'is_favorite': isFavorite,
				}),
			);
			if (response.statusCode == 200) {
				return json.decode(response.body);
			}
			final body = json.decode(response.body);
			return {'success': false, 'message': body['message'] ?? 'Failed to create project'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> deleteTeam(String teamName) async {
		final url = Uri.parse('$_baseUrl/team/${Uri.encodeComponent(teamName)}');
		final headers = await _getHeaders();
		try {
			final response = await http.delete(url, headers: headers);
			final body = json.decode(response.body);
			if (response.statusCode == 200) return {'success': true, 'message': body['message']};
			return {'success': false, 'message': body['message'] ?? 'Failed to delete team'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> deleteProject(String projectId) async {
		final url = Uri.parse('$_baseUrl/projects/$projectId');
		final headers = await _getHeaders();
		try {
			final response = await http.delete(url, headers: headers);
			final body = json.decode(response.body);
			if (response.statusCode == 200) return {'success': true, 'message': body['message']};
			return {'success': false, 'message': body['message'] ?? 'Failed to delete project'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> getNotes() async {
		final url = Uri.parse('$_baseUrl/notes');
		final headers = await _getHeaders();
		try {
			final response = await http.get(url, headers: headers);
			if (response.statusCode == 200) {
				final body = json.decode(response.body);
				return {'success': true, 'notes': body};
			}
			final body = json.decode(response.body);
			return {'success': false, 'message': body['message'] ?? 'Failed to fetch notes'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}

	Future<Map<String, dynamic>> addNote({
		required String type,
		String? content,
		String? mediaBase64,
	}) async {
		final url = Uri.parse('$_baseUrl/notes');
		final headers = await _getHeaders();
		try {
			final response = await http.post(
				url,
				headers: headers,
				body: json.encode({
					'type': type,
					'content': content,
					'media_base64': mediaBase64,
				}),
			);
			if (response.statusCode == 200) return {'success': true};
			final body = json.decode(response.body);
			return {'success': false, 'message': body['message'] ?? 'Failed to add note'};
		} catch (e) {
			return {'success': false, 'message': 'Network error occurred.'};
		}
	}
}
