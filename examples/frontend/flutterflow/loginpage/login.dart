import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/backend/schema/structs/index.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import '../login_page_model.dart';
export '../login_page_model.dart';

class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  static String routeName = 'LoginPage';
  static String routePath = '/loginPage';

  @override
  State<LoginPageWidget> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginPageWidget> {
  late LoginPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await actions.initWebSocket2(context);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Spacer(flex: 2),
              Stack(
                children: [
                  Align(
                    alignment: AlignmentDirectional(0, 0),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(0, 40, 0, 0),
                      child: Text(
                        'Timingle',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.readexPro(
                            fontWeight: FontWeight.w900,
                            fontStyle: FlutterFlowTheme.of(
                              context,
                            ).bodyMedium.fontStyle,
                          ),
                          fontSize: 60,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w900,
                          fontStyle: FlutterFlowTheme.of(
                            context,
                          ).bodyMedium.fontStyle,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional(0, -1),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(200, 0, 0, 0),
                      child: Icon(
                        Icons.chat_outlined,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        size: 70,
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(flex: 2),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
                child: FFButtonWidget(
                  onPressed: () async {
                    Function() _navigate = () {};
                    _model.refreshTokenResult = await RefreshTokenCall.call(
                      deviceId: FFAppState().deviceId,
                      refreshToken: FFAppState().refreshToken,
                    );

                    if ((_model.refreshTokenResult?.statusCode ?? 200) == 200) {
                      GoRouter.of(context).prepareAuthEvent();
                      await authManager.signIn(
                        authenticationToken: UserInfoStruct.maybeFromMap(
                          (_model.refreshTokenResult?.jsonBody ?? ''),
                        )?.accessToken,
                        refreshToken: UserInfoStruct.maybeFromMap(
                          (_model.refreshTokenResult?.jsonBody ?? ''),
                        )?.refreshToken,
                        authUid: UserInfoStruct.maybeFromMap(
                          (_model.refreshTokenResult?.jsonBody ?? ''),
                        )?.userId,
                        userData: UserInfoStruct.maybeFromMap(
                          (_model.refreshTokenResult?.jsonBody ?? ''),
                        ),
                      );
                      _navigate = () => context.goNamedAuth(
                        FriendsPageWidget.routeName,
                        context.mounted,
                      );
                    } else {
                      var confirmDialogResponse =
                          await showDialog<bool>(
                            context: context,
                            builder: (alertDialogContext) {
                              return WebViewAware(
                                child: AlertDialog(
                                  title: Text('Subscribe'),
                                  content: Text('google subscribe'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(
                                        alertDialogContext,
                                        false,
                                      ),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(
                                        alertDialogContext,
                                        true,
                                      ),
                                      child: Text('Confirm'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ) ??
                          false;
                      if (confirmDialogResponse) {
                        await launchURL(
                          '${FFAppState().serverUrl}${FFAppState().googleSubscribeUri}?deviceId=${FFAppState().deviceId}',
                        );
                      }
                    }

                    _navigate();

                    safeSetState(() {});
                  },
                  text: 'Continue with Google',
                  icon: FaIcon(FontAwesomeIcons.google, size: 20),
                  options: FFButtonOptions(
                    width: 230,
                    height: 44,
                    padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                    iconPadding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.readexPro(
                        fontWeight: FontWeight.bold,
                        fontStyle: FlutterFlowTheme.of(
                          context,
                        ).bodyMedium.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                      fontStyle: FlutterFlowTheme.of(
                        context,
                      ).bodyMedium.fontStyle,
                    ),
                    elevation: 0,
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    hoverColor: FlutterFlowTheme.of(context).primaryBackground,
                  ),
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
