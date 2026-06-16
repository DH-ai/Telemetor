import 'package:flutter/material.dart';

import 'tokens/colors.dart';
import 'typography/text_styles.dart';

/// Convenience accessors for TDL tokens on [BuildContext].
extension TDLContext on BuildContext {
  TDLColors get tdlColors => TDLColors.of(this);
  TDLTextStyles get tdlText => TDLTextStyles.of(this);
}
