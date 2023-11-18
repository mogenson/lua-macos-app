local class = require("class")
local ffi = require("ffi")
ffi.cdef [[
typedef struct uiInitOptions uiInitOptions;
struct uiInitOptions {
 size_t Size;
};
extern const char *uiInit(uiInitOptions *options);
extern void uiUninit(void);
extern void uiFreeInitError(const char *err);
extern void uiMain(void);
extern void uiMainSteps(void);
extern int uiMainStep(int wait);
extern void uiQuit(void);
extern void uiQueueMain(void (*f)(void *data), void *data);
extern void uiOnShouldQuit(int (*f)(void *data), void *data);
extern void uiFreeText(char *text);
typedef struct uiControl uiControl;
struct uiControl {
 uint32_t Signature;
 uint32_t OSSignature;
 uint32_t TypeSignature;
 void (*Destroy)(uiControl *);
 uintptr_t (*Handle)(uiControl *);
 uiControl *(*Parent)(uiControl *);
 void (*SetParent)(uiControl *, uiControl *);
 int (*Toplevel)(uiControl *);
 int (*Visible)(uiControl *);
 void (*Show)(uiControl *);
 void (*Hide)(uiControl *);
 int (*Enabled)(uiControl *);
 void (*Enable)(uiControl *);
 void (*Disable)(uiControl *);
};
extern void uiControlDestroy(uiControl *);
extern uintptr_t uiControlHandle(uiControl *);
extern uiControl *uiControlParent(uiControl *);
extern void uiControlSetParent(uiControl *, uiControl *);
extern int uiControlToplevel(uiControl *);
extern int uiControlVisible(uiControl *);
extern void uiControlShow(uiControl *);
extern void uiControlHide(uiControl *);
extern int uiControlEnabled(uiControl *);
extern void uiControlEnable(uiControl *);
extern void uiControlDisable(uiControl *);
extern uiControl *uiAllocControl(size_t n, uint32_t OSsig, uint32_t typesig, const char *typenamestr);
extern void uiFreeControl(uiControl *);
extern void uiControlVerifySetParent(uiControl *, uiControl *);
extern int uiControlEnabledToUser(uiControl *);
extern void uiUserBugCannotSetParentOnToplevel(const char *type);
typedef struct uiWindow uiWindow;
extern char *uiWindowTitle(uiWindow *w);
extern void uiWindowSetTitle(uiWindow *w, const char *title);
extern void uiWindowPosition(uiWindow *w, int *x, int *y);
extern void uiWindowSetPosition(uiWindow *w, int x, int y);
extern void uiWindowCenter(uiWindow *w);
extern void uiWindowOnPositionChanged(uiWindow *w, void (*f)(uiWindow *, void *), void *data);
extern void uiWindowContentSize(uiWindow *w, int *width, int *height);
extern void uiWindowSetContentSize(uiWindow *w, int width, int height);
extern int uiWindowFullscreen(uiWindow *w);
extern void uiWindowSetFullscreen(uiWindow *w, int fullscreen);
extern void uiWindowOnContentSizeChanged(uiWindow *w, void (*f)(uiWindow *, void *), void *data);
extern void uiWindowOnClosing(uiWindow *w, int (*f)(uiWindow *w, void *data), void *data);
extern int uiWindowBorderless(uiWindow *w);
extern void uiWindowSetBorderless(uiWindow *w, int borderless);
extern void uiWindowSetChild(uiWindow *w, uiControl *child);
extern int uiWindowMargined(uiWindow *w);
extern void uiWindowSetMargined(uiWindow *w, int margined);
extern uiWindow *uiNewWindow(const char *title, int width, int height, int hasMenubar);
typedef struct uiButton uiButton;
extern char *uiButtonText(uiButton *b);
extern void uiButtonSetText(uiButton *b, const char *text);
extern void uiButtonOnClicked(uiButton *b, void (*f)(uiButton *b, void *data), void *data);
extern uiButton *uiNewButton(const char *text);
typedef struct uiBox uiBox;
extern void uiBoxAppend(uiBox *b, uiControl *child, int stretchy);
extern void uiBoxDelete(uiBox *b, int index);
extern int uiBoxPadded(uiBox *b);
extern void uiBoxSetPadded(uiBox *b, int padded);
extern uiBox *uiNewHorizontalBox(void);
extern uiBox *uiNewVerticalBox(void);
typedef struct uiCheckbox uiCheckbox;
extern char *uiCheckboxText(uiCheckbox *c);
extern void uiCheckboxSetText(uiCheckbox *c, const char *text);
extern void uiCheckboxOnToggled(uiCheckbox *c, void (*f)(uiCheckbox *c, void *data), void *data);
extern int uiCheckboxChecked(uiCheckbox *c);
extern void uiCheckboxSetChecked(uiCheckbox *c, int checked);
extern uiCheckbox *uiNewCheckbox(const char *text);
typedef struct uiEntry uiEntry;
extern char *uiEntryText(uiEntry *e);
extern void uiEntrySetText(uiEntry *e, const char *text);
extern void uiEntryOnChanged(uiEntry *e, void (*f)(uiEntry *e, void *data), void *data);
extern int uiEntryReadOnly(uiEntry *e);
extern void uiEntrySetReadOnly(uiEntry *e, int readonly);
extern uiEntry *uiNewEntry(void);
extern uiEntry *uiNewPasswordEntry(void);
extern uiEntry *uiNewSearchEntry(void);
typedef struct uiLabel uiLabel;
extern char *uiLabelText(uiLabel *l);
extern void uiLabelSetText(uiLabel *l, const char *text);
extern uiLabel *uiNewLabel(const char *text);
typedef struct uiTab uiTab;
extern void uiTabAppend(uiTab *t, const char *name, uiControl *c);
extern void uiTabInsertAt(uiTab *t, const char *name, int before, uiControl *c);
extern void uiTabDelete(uiTab *t, int index);
extern int uiTabNumPages(uiTab *t);
extern int uiTabMargined(uiTab *t, int page);
extern void uiTabSetMargined(uiTab *t, int page, int margined);
extern uiTab *uiNewTab(void);
typedef struct uiGroup uiGroup;
extern char *uiGroupTitle(uiGroup *g);
extern void uiGroupSetTitle(uiGroup *g, const char *title);
extern void uiGroupSetChild(uiGroup *g, uiControl *c);
extern int uiGroupMargined(uiGroup *g);
extern void uiGroupSetMargined(uiGroup *g, int margined);
extern uiGroup *uiNewGroup(const char *title);
typedef struct uiSpinbox uiSpinbox;
extern int uiSpinboxValue(uiSpinbox *s);
extern void uiSpinboxSetValue(uiSpinbox *s, int value);
extern void uiSpinboxOnChanged(uiSpinbox *s, void (*f)(uiSpinbox *s, void *data), void *data);
extern uiSpinbox *uiNewSpinbox(int min, int max);
typedef struct uiSlider uiSlider;
extern int uiSliderValue(uiSlider *s);
extern void uiSliderSetValue(uiSlider *s, int value);
extern void uiSliderOnChanged(uiSlider *s, void (*f)(uiSlider *s, void *data), void *data);
extern uiSlider *uiNewSlider(int min, int max);
typedef struct uiProgressBar uiProgressBar;
extern int uiProgressBarValue(uiProgressBar *p);
extern void uiProgressBarSetValue(uiProgressBar *p, int n);
extern uiProgressBar *uiNewProgressBar(void);
typedef struct uiSeparator uiSeparator;
extern uiSeparator *uiNewHorizontalSeparator(void);
extern uiSeparator *uiNewVerticalSeparator(void);
typedef struct uiCombobox uiCombobox;
extern void uiComboboxAppend(uiCombobox *c, const char *text);
extern int uiComboboxSelected(uiCombobox *c);
extern void uiComboboxSetSelected(uiCombobox *c, int n);
extern void uiComboboxOnSelected(uiCombobox *c, void (*f)(uiCombobox *c, void *data), void *data);
extern uiCombobox *uiNewCombobox(void);
typedef struct uiEditableCombobox uiEditableCombobox;
extern void uiEditableComboboxAppend(uiEditableCombobox *c, const char *text);
extern char *uiEditableComboboxText(uiEditableCombobox *c);
extern void uiEditableComboboxSetText(uiEditableCombobox *c, const char *text);
extern void uiEditableComboboxOnChanged(uiEditableCombobox *c, void (*f)(uiEditableCombobox *c, void *data), void *data);
extern uiEditableCombobox *uiNewEditableCombobox(void);
typedef struct uiRadioButtons uiRadioButtons;
extern void uiRadioButtonsAppend(uiRadioButtons *r, const char *text);
extern int uiRadioButtonsSelected(uiRadioButtons *r);
extern void uiRadioButtonsSetSelected(uiRadioButtons *r, int n);
extern void uiRadioButtonsOnSelected(uiRadioButtons *r, void (*f)(uiRadioButtons *, void *), void *data);
extern uiRadioButtons *uiNewRadioButtons(void);
typedef struct uiDateTimePicker uiDateTimePicker;
extern uiDateTimePicker *uiNewDateTimePicker(void);
extern uiDateTimePicker *uiNewDatePicker(void);
extern uiDateTimePicker *uiNewTimePicker(void);
typedef struct uiMultilineEntry uiMultilineEntry;
extern char *uiMultilineEntryText(uiMultilineEntry *e);
extern void uiMultilineEntrySetText(uiMultilineEntry *e, const char *text);
extern void uiMultilineEntryAppend(uiMultilineEntry *e, const char *text);
extern void uiMultilineEntryOnChanged(uiMultilineEntry *e, void (*f)(uiMultilineEntry *e, void *data), void *data);
extern int uiMultilineEntryReadOnly(uiMultilineEntry *e);
extern void uiMultilineEntrySetReadOnly(uiMultilineEntry *e, int readonly);
extern uiMultilineEntry *uiNewMultilineEntry(void);
extern uiMultilineEntry *uiNewNonWrappingMultilineEntry(void);
typedef struct uiMenuItem uiMenuItem;
extern void uiMenuItemEnable(uiMenuItem *m);
extern void uiMenuItemDisable(uiMenuItem *m);
extern void uiMenuItemOnClicked(uiMenuItem *m, void (*f)(uiMenuItem *sender, uiWindow *window, void *data), void *data);
extern int uiMenuItemChecked(uiMenuItem *m);
extern void uiMenuItemSetChecked(uiMenuItem *m, int checked);
typedef struct uiMenu uiMenu;
extern uiMenuItem *uiMenuAppendItem(uiMenu *m, const char *name);
extern uiMenuItem *uiMenuAppendCheckItem(uiMenu *m, const char *name);
extern uiMenuItem *uiMenuAppendQuitItem(uiMenu *m);
extern uiMenuItem *uiMenuAppendPreferencesItem(uiMenu *m);
extern uiMenuItem *uiMenuAppendAboutItem(uiMenu *m);
extern void uiMenuAppendSeparator(uiMenu *m);
extern uiMenu *uiNewMenu(const char *name);
extern char *uiOpenFile(uiWindow *parent);
extern char *uiSaveFile(uiWindow *parent);
extern void uiMsgBox(uiWindow *parent, const char *title, const char *description);
extern void uiMsgBoxError(uiWindow *parent, const char *title, const char *description);
typedef struct uiArea uiArea;
typedef struct uiAreaHandler uiAreaHandler;
typedef struct uiAreaDrawParams uiAreaDrawParams;
typedef struct uiAreaMouseEvent uiAreaMouseEvent;
typedef struct uiAreaKeyEvent uiAreaKeyEvent;
typedef struct uiDrawContext uiDrawContext;
struct uiAreaHandler {
 void (*Draw)(uiAreaHandler *, uiArea *, uiAreaDrawParams *);
 void (*MouseEvent)(uiAreaHandler *, uiArea *, uiAreaMouseEvent *);
 void (*MouseCrossed)(uiAreaHandler *, uiArea *, int left);
 void (*DragBroken)(uiAreaHandler *, uiArea *);
 int (*KeyEvent)(uiAreaHandler *, uiArea *, uiAreaKeyEvent *);
};
extern void uiAreaSetSize(uiArea *a, int width, int height);
extern void uiAreaQueueRedrawAll(uiArea *a);
extern void uiAreaScrollTo(uiArea *a, double x, double y, double width, double height);
extern uiArea *uiNewArea(uiAreaHandler *ah);
extern uiArea *uiNewScrollingArea(uiAreaHandler *ah, int width, int height);
struct uiAreaDrawParams {
 uiDrawContext *Context;
 double AreaWidth;
 double AreaHeight;
 double ClipX;
 double ClipY;
 double ClipWidth;
 double ClipHeight;
};
typedef struct uiDrawPath uiDrawPath;
typedef struct uiDrawBrush uiDrawBrush;
typedef struct uiDrawStrokeParams uiDrawStrokeParams;
typedef struct uiDrawMatrix uiDrawMatrix;
typedef struct uiDrawBrushGradientStop uiDrawBrushGradientStop;
typedef unsigned int uiDrawBrushType; enum {
 uiDrawBrushTypeSolid,
 uiDrawBrushTypeLinearGradient,
 uiDrawBrushTypeRadialGradient,
 uiDrawBrushTypeImage,
};
typedef unsigned int uiDrawLineCap; enum {
 uiDrawLineCapFlat,
 uiDrawLineCapRound,
 uiDrawLineCapSquare,
};
typedef unsigned int uiDrawLineJoin; enum {
 uiDrawLineJoinMiter,
 uiDrawLineJoinRound,
 uiDrawLineJoinBevel,
};
typedef unsigned int uiDrawFillMode; enum {
 uiDrawFillModeWinding,
 uiDrawFillModeAlternate,
};
struct uiDrawMatrix {
 double M11;
 double M12;
 double M21;
 double M22;
 double M31;
 double M32;
};
struct uiDrawBrush {
 uiDrawBrushType Type;
 double R;
 double G;
 double B;
 double A;
 double X0;
 double Y0;
 double X1;
 double Y1;
 double OuterRadius;
 uiDrawBrushGradientStop *Stops;
 size_t NumStops;
};
struct uiDrawBrushGradientStop {
 double Pos;
 double R;
 double G;
 double B;
 double A;
};
struct uiDrawStrokeParams {
 uiDrawLineCap Cap;
 uiDrawLineJoin Join;
 double Thickness;
 double MiterLimit;
 double *Dashes;
 size_t NumDashes;
 double DashPhase;
};
extern uiDrawPath *uiDrawNewPath(uiDrawFillMode fillMode);
extern void uiDrawFreePath(uiDrawPath *p);
extern void uiDrawPathNewFigure(uiDrawPath *p, double x, double y);
extern void uiDrawPathNewFigureWithArc(uiDrawPath *p, double xCenter, double yCenter, double radius, double startAngle, double sweep, int negative);
extern void uiDrawPathLineTo(uiDrawPath *p, double x, double y);
extern void uiDrawPathArcTo(uiDrawPath *p, double xCenter, double yCenter, double radius, double startAngle, double sweep, int negative);
extern void uiDrawPathBezierTo(uiDrawPath *p, double c1x, double c1y, double c2x, double c2y, double endX, double endY);
extern void uiDrawPathCloseFigure(uiDrawPath *p);
extern void uiDrawPathAddRectangle(uiDrawPath *p, double x, double y, double width, double height);
extern void uiDrawPathEnd(uiDrawPath *p);
extern void uiDrawStroke(uiDrawContext *c, uiDrawPath *path, uiDrawBrush *b, uiDrawStrokeParams *p);
extern void uiDrawFill(uiDrawContext *c, uiDrawPath *path, uiDrawBrush *b);
extern void uiDrawMatrixSetIdentity(uiDrawMatrix *m);
extern void uiDrawMatrixTranslate(uiDrawMatrix *m, double x, double y);
extern void uiDrawMatrixScale(uiDrawMatrix *m, double xCenter, double yCenter, double x, double y);
extern void uiDrawMatrixRotate(uiDrawMatrix *m, double x, double y, double amount);
extern void uiDrawMatrixSkew(uiDrawMatrix *m, double x, double y, double xamount, double yamount);
extern void uiDrawMatrixMultiply(uiDrawMatrix *dest, uiDrawMatrix *src);
extern int uiDrawMatrixInvertible(uiDrawMatrix *m);
extern int uiDrawMatrixInvert(uiDrawMatrix *m);
extern void uiDrawMatrixTransformPoint(uiDrawMatrix *m, double *x, double *y);
extern void uiDrawMatrixTransformSize(uiDrawMatrix *m, double *x, double *y);
extern void uiDrawTransform(uiDrawContext *c, uiDrawMatrix *m);
extern void uiDrawClip(uiDrawContext *c, uiDrawPath *path);
extern void uiDrawSave(uiDrawContext *c);
extern void uiDrawRestore(uiDrawContext *c);
typedef struct uiDrawFontFamilies uiDrawFontFamilies;
extern uiDrawFontFamilies *uiDrawListFontFamilies(void);
extern int uiDrawFontFamiliesNumFamilies(uiDrawFontFamilies *ff);
extern char *uiDrawFontFamiliesFamily(uiDrawFontFamilies *ff, int n);
extern void uiDrawFreeFontFamilies(uiDrawFontFamilies *ff);
typedef struct uiDrawTextLayout uiDrawTextLayout;
typedef struct uiDrawTextFont uiDrawTextFont;
typedef struct uiDrawTextFontDescriptor uiDrawTextFontDescriptor;
typedef struct uiDrawTextFontMetrics uiDrawTextFontMetrics;
typedef unsigned int uiDrawTextWeight; enum {
 uiDrawTextWeightThin,
 uiDrawTextWeightUltraLight,
 uiDrawTextWeightLight,
 uiDrawTextWeightBook,
 uiDrawTextWeightNormal,
 uiDrawTextWeightMedium,
 uiDrawTextWeightSemiBold,
 uiDrawTextWeightBold,
 uiDrawTextWeightUtraBold,
 uiDrawTextWeightHeavy,
 uiDrawTextWeightUltraHeavy,
};
typedef unsigned int uiDrawTextItalic; enum {
 uiDrawTextItalicNormal,
 uiDrawTextItalicOblique,
 uiDrawTextItalicItalic,
};
typedef unsigned int uiDrawTextStretch; enum {
 uiDrawTextStretchUltraCondensed,
 uiDrawTextStretchExtraCondensed,
 uiDrawTextStretchCondensed,
 uiDrawTextStretchSemiCondensed,
 uiDrawTextStretchNormal,
 uiDrawTextStretchSemiExpanded,
 uiDrawTextStretchExpanded,
 uiDrawTextStretchExtraExpanded,
 uiDrawTextStretchUltraExpanded,
};
struct uiDrawTextFontDescriptor {
 const char *Family;
 double Size;
 uiDrawTextWeight Weight;
 uiDrawTextItalic Italic;
 uiDrawTextStretch Stretch;
};
struct uiDrawTextFontMetrics {
 double Ascent;
 double Descent;
 double Leading;
 double UnderlinePos;
 double UnderlineThickness;
};
extern uiDrawTextFont *uiDrawLoadClosestFont(const uiDrawTextFontDescriptor *desc);
extern void uiDrawFreeTextFont(uiDrawTextFont *font);
extern uintptr_t uiDrawTextFontHandle(uiDrawTextFont *font);
extern void uiDrawTextFontDescribe(uiDrawTextFont *font, uiDrawTextFontDescriptor *desc);
extern void uiDrawTextFontGetMetrics(uiDrawTextFont *font, uiDrawTextFontMetrics *metrics);
extern uiDrawTextLayout *uiDrawNewTextLayout(const char *text, uiDrawTextFont *defaultFont, double width);
extern void uiDrawFreeTextLayout(uiDrawTextLayout *layout);
extern void uiDrawTextLayoutSetWidth(uiDrawTextLayout *layout, double width);
extern void uiDrawTextLayoutExtents(uiDrawTextLayout *layout, double *width, double *height);
extern void uiDrawTextLayoutSetColor(uiDrawTextLayout *layout, int startChar, int endChar, double r, double g, double b, double a);
extern void uiDrawText(uiDrawContext *c, double x, double y, uiDrawTextLayout *layout);
typedef unsigned int uiModifiers; enum {
 uiModifierCtrl = 1 << 0,
 uiModifierAlt = 1 << 1,
 uiModifierShift = 1 << 2,
 uiModifierSuper = 1 << 3,
};
struct uiAreaMouseEvent {
 double X;
 double Y;
 double AreaWidth;
 double AreaHeight;
 int Down;
 int Up;
 int Count;
 uiModifiers Modifiers;
 uint64_t Held1To64;
};
typedef unsigned int uiExtKey; enum {
 uiExtKeyEscape = 1,
 uiExtKeyInsert,
 uiExtKeyDelete,
 uiExtKeyHome,
 uiExtKeyEnd,
 uiExtKeyPageUp,
 uiExtKeyPageDown,
 uiExtKeyUp,
 uiExtKeyDown,
 uiExtKeyLeft,
 uiExtKeyRight,
 uiExtKeyF1,
 uiExtKeyF2,
 uiExtKeyF3,
 uiExtKeyF4,
 uiExtKeyF5,
 uiExtKeyF6,
 uiExtKeyF7,
 uiExtKeyF8,
 uiExtKeyF9,
 uiExtKeyF10,
 uiExtKeyF11,
 uiExtKeyF12,
 uiExtKeyN0,
 uiExtKeyN1,
 uiExtKeyN2,
 uiExtKeyN3,
 uiExtKeyN4,
 uiExtKeyN5,
 uiExtKeyN6,
 uiExtKeyN7,
 uiExtKeyN8,
 uiExtKeyN9,
 uiExtKeyNDot,
 uiExtKeyNEnter,
 uiExtKeyNAdd,
 uiExtKeyNSubtract,
 uiExtKeyNMultiply,
 uiExtKeyNDivide,
};
struct uiAreaKeyEvent {
 char Key;
 uiExtKey ExtKey;
 uiModifiers Modifier;
 uiModifiers Modifiers;
 int Up;
};
typedef struct uiFontButton uiFontButton;
extern uiDrawTextFont *uiFontButtonFont(uiFontButton *b);
extern void uiFontButtonOnChanged(uiFontButton *b, void (*f)(uiFontButton *, void *), void *data);
extern uiFontButton *uiNewFontButton(void);
typedef struct uiColorButton uiColorButton;
extern void uiColorButtonColor(uiColorButton *b, double *r, double *g, double *bl, double *a);
extern void uiColorButtonSetColor(uiColorButton *b, double r, double g, double bl, double a);
extern void uiColorButtonOnChanged(uiColorButton *b, void (*f)(uiColorButton *, void *), void *data);
extern uiColorButton *uiNewColorButton(void);
typedef struct uiForm uiForm;
extern void uiFormAppend(uiForm *f, const char *label, uiControl *c, int stretchy);
extern void uiFormDelete(uiForm *f, int index);
extern int uiFormPadded(uiForm *f);
extern void uiFormSetPadded(uiForm *f, int padded);
extern uiForm *uiNewForm(void);
typedef unsigned int uiAlign; enum {
 uiAlignFill,
 uiAlignStart,
 uiAlignCenter,
 uiAlignEnd,
};
typedef unsigned int uiAt; enum {
 uiAtLeading,
 uiAtTop,
 uiAtTrailing,
 uiAtBottom,
};
typedef struct uiGrid uiGrid;
extern void uiGridAppend(uiGrid *g, uiControl *c, int left, int top, int xspan, int yspan, int hexpand, uiAlign halign, int vexpand, uiAlign valign);
extern void uiGridInsertAt(uiGrid *g, uiControl *c, uiControl *existing, uiAt at, int xspan, int yspan, int hexpand, uiAlign halign, int vexpand, uiAlign valign);
extern int uiGridPadded(uiGrid *g);
extern void uiGridSetPadded(uiGrid *g, int padded);
extern uiGrid *uiNewGrid(void);
]]
local _lib = ffi.load("ui")

local M = class(class.properties)

local function _checkcstr(s)
    if s == nil then
        return nil
    else
        local res = ffi.string(s)
        _lib.uiFreeText(s)
        return res
    end
end

local function _checkbool(n) return n == 1 end

local function readonly(t)
    local mt = {
        __index = t,
        __newindex = function(t, k, v) error("Attempt to modify read-only table", 2) end,
        __pairs = function() return pairs(t) end,
        __ipairs = function() return ipairs(t) end,
        __len = function() return #t end,
        __metatable = false
    }
    return setmetatable({}, mt)
end

M.Align = readonly {
    Fill = 0,
    Start = 1,
    Center = 2,
    End = 3,
}

M.At = readonly {
    Leading = 0,
    Top = 1,
    Trailing = 2,
    Bottom = 3,
}

local Control = class(class.properties)

function Control:VerifySetParent(arg)
    _lib.uiControlVerifySetParent(ffi.cast("uiControl*", self._raw), ffi.cast("uiControl*", arg._raw))
end

function Control:EnabledToUser()
    return _checkbool(_lib.uiControlEnabledToUser(ffi.cast("uiControl*", self._raw)))
end

function Control:set_Parent(arg)
    _lib.uiControlSetParent(ffi.cast("uiControl*", self._raw), ffi.cast("uiControl*", arg._raw))
end

function Control:Toplevel()
    return _checkbool(_lib.uiControlToplevel(ffi.cast("uiControl*", self._raw)))
end

function Control:Destroy()
    _lib.uiControlDestroy(ffi.cast("uiControl*", self._raw))
end

function Control:Visible()
    return _checkbool(_lib.uiControlVisible(ffi.cast("uiControl*", self._raw)))
end

function Control:Enabled()
    return _checkbool(_lib.uiControlEnabled(ffi.cast("uiControl*", self._raw)))
end

function Control:Disable()
    _lib.uiControlDisable(ffi.cast("uiControl*", self._raw))
end

function Control:Handle()
    return _lib.uiControlHandle(ffi.cast("uiControl*", self._raw))
end

function Control:get_Parent()
    return _lib.uiControlParent(ffi.cast("uiControl*", self._raw))
end

function Control:Enable()
    _lib.uiControlEnable(ffi.cast("uiControl*", self._raw))
end

function Control:Show()
    _lib.uiControlShow(ffi.cast("uiControl*", self._raw))
end

function Control:Hide()
    _lib.uiControlHide(ffi.cast("uiControl*", self._raw))
end

Control._name = "Control"
M.Control = Control

local Box = class(Control)

function Box:set_Padded(padded)
    _lib.uiBoxSetPadded(self._raw, padded)
end

function Box:get_Padded()
    return _checkbool(_lib.uiBoxPadded(self._raw))
end

function Box:Delete(index)
    _lib.uiBoxDelete(self._raw, index)
end

function Box:Append(child, stretchy)
    _lib.uiBoxAppend(self._raw, ffi.cast("uiControl*", child._raw), stretchy)
end

Box._name = "Box"
M.Box = Box

local Button = class(Control)

function Button:_init(text)
    self._raw = _lib.uiNewButton(text)
end

function Button:set_OnClicked(cb)
    _lib.uiButtonOnClicked(self._raw, function() return cb() end, nil)
end

function Button:set_Text(text)
    _lib.uiButtonSetText(self._raw, text)
end

function Button:get_Text()
    return _checkcstr(_lib.uiButtonText(self._raw))
end

Button._name = "Button"
M.Button = Button

local Checkbox = class(Control)

function Checkbox:_init(text)
    self._raw = _lib.uiNewCheckbox(text)
end

function Checkbox:set_OnToggled(cb)
    _lib.uiCheckboxOnToggled(self._raw, function() return cb() end, nil)
end

function Checkbox:set_Checked(checked)
    _lib.uiCheckboxSetChecked(self._raw, checked)
end

function Checkbox:set_Text(text)
    _lib.uiCheckboxSetText(self._raw, text)
end

function Checkbox:get_Checked()
    return _checkbool(_lib.uiCheckboxChecked(self._raw))
end

function Checkbox:get_Text()
    return _checkcstr(_lib.uiCheckboxText(self._raw))
end

Checkbox._name = "Checkbox"
M.Checkbox = Checkbox

local ColorButton = class(Control)

function ColorButton:_init()
    self._raw = _lib.uiNewColorButton()
end

function ColorButton:set_OnChanged(cb)
    _lib.uiColorButtonOnChanged(self._raw, function() return cb() end, nil)
end

function ColorButton:SetColor(r, g, bl, a)
    _lib.uiColorButtonSetColor(self._raw, r, g, bl, a)
end

function ColorButton:Color(r, g, bl, a)
    _lib.uiColorButtonColor(self._raw, r, g, bl, a)
end

ColorButton._name = "ColorButton"
M.ColorButton = ColorButton

local Combobox = class(Control)

function Combobox:_init()
    self._raw = _lib.uiNewCombobox()
end

function Combobox:set_OnSelected(cb)
    _lib.uiComboboxOnSelected(self._raw, function() return cb() end, nil)
end

function Combobox:set_Selected(n)
    _lib.uiComboboxSetSelected(self._raw, n)
end

function Combobox:get_Selected()
    return _lib.uiComboboxSelected(self._raw)
end

function Combobox:Append(text)
    _lib.uiComboboxAppend(self._raw, text)
end

Combobox._name = "Combobox"
M.Combobox = Combobox

local DatePicker = class(Control)

function DatePicker:_init()
    self._raw = _lib.uiNewDatePicker()
end

DatePicker._name = "DatePicker"
M.DatePicker = DatePicker

local DateTimePicker = class(Control)

function DateTimePicker:_init()
    self._raw = _lib.uiNewDateTimePicker()
end

DateTimePicker._name = "DateTimePicker"
M.DateTimePicker = DateTimePicker

local EditableCombobox = class(Control)

function EditableCombobox:_init()
    self._raw = _lib.uiNewEditableCombobox()
end

function EditableCombobox:set_OnChanged(cb)
    _lib.uiEditableComboboxOnChanged(self._raw, function() return cb() end, nil)
end

function EditableCombobox:set_Text(text)
    _lib.uiEditableComboboxSetText(self._raw, text)
end

function EditableCombobox:Append(text)
    _lib.uiEditableComboboxAppend(self._raw, text)
end

function EditableCombobox:get_Text()
    return _checkcstr(_lib.uiEditableComboboxText(self._raw))
end

EditableCombobox._name = "EditableCombobox"
M.EditableCombobox = EditableCombobox

local Entry = class(Control)

function Entry:_init()
    self._raw = _lib.uiNewEntry()
end

function Entry:set_OnChanged(cb)
    _lib.uiEntryOnChanged(self._raw, function() return cb() end, nil)
end

function Entry:set_ReadOnly(readonly)
    _lib.uiEntrySetReadOnly(self._raw, readonly)
end

function Entry:get_ReadOnly()
    return _checkbool(_lib.uiEntryReadOnly(self._raw))
end

function Entry:set_Text(text)
    _lib.uiEntrySetText(self._raw, text)
end

function Entry:get_Text()
    return _checkcstr(_lib.uiEntryText(self._raw))
end

Entry._name = "Entry"
M.Entry = Entry

local FontButton = class(Control)

function FontButton:_init()
    self._raw = _lib.uiNewFontButton()
end

function FontButton:set_OnChanged(cb)
    _lib.uiFontButtonOnChanged(self._raw, function() return cb() end, nil)
end

function FontButton:Font()
    return _lib.uiFontButtonFont(self._raw)
end

FontButton._name = "FontButton"
M.FontButton = FontButton

local Form = class(Control)

function Form:_init()
    self._raw = _lib.uiNewForm()
end

function Form:set_Padded(padded)
    _lib.uiFormSetPadded(self._raw, padded)
end

function Form:get_Padded()
    return _checkbool(_lib.uiFormPadded(self._raw))
end

function Form:Delete(index)
    _lib.uiFormDelete(self._raw, index)
end

function Form:Append(label, c, stretchy)
    _lib.uiFormAppend(self._raw, label, ffi.cast("uiControl*", c._raw), stretchy)
end

Form._name = "Form"
M.Form = Form

local Grid = class(Control)

function Grid:_init()
    self._raw = _lib.uiNewGrid()
end

function Grid:set_Padded(padded)
    _lib.uiGridSetPadded(self._raw, padded)
end

function Grid:InsertAt(c, existing, at, xspan, yspan, hexpand, halign, vexpand, valign)
    _lib.uiGridInsertAt(self._raw, ffi.cast("uiControl*", c._raw), ffi.cast("uiControl*", existing._raw), at, xspan,
        yspan, hexpand, halign, vexpand, valign)
end

function Grid:get_Padded()
    return _checkbool(_lib.uiGridPadded(self._raw))
end

function Grid:Append(c, left, top, xspan, yspan, hexpand, halign, vexpand, valign)
    _lib.uiGridAppend(self._raw, ffi.cast("uiControl*", c._raw), left, top, xspan, yspan, hexpand, halign, vexpand,
        valign)
end

Grid._name = "Grid"
M.Grid = Grid

local Group = class(Control)

function Group:_init(title)
    self._raw = _lib.uiNewGroup(title)
end

function Group:set_Margined(margined)
    _lib.uiGroupSetMargined(self._raw, margined)
end

function Group:set_Title(title)
    _lib.uiGroupSetTitle(self._raw, title)
end

function Group:get_Margined()
    return _checkbool(_lib.uiGroupMargined(self._raw))
end

function Group:set_Child(c)
    _lib.uiGroupSetChild(self._raw, ffi.cast("uiControl*", c._raw))
end

function Group:get_Title()
    return _checkcstr(_lib.uiGroupTitle(self._raw))
end

Group._name = "Group"
M.Group = Group

local HorizontalBox = class(Box)

function HorizontalBox:_init()
    self._raw = _lib.uiNewHorizontalBox()
end

HorizontalBox._name = "HorizontalBox"
M.HorizontalBox = HorizontalBox

local HorizontalSeparator = class(Control)

function HorizontalSeparator:_init()
    self._raw = _lib.uiNewHorizontalSeparator()
end

HorizontalSeparator._name = "HorizontalSeparator"
M.HorizontalSeparator = HorizontalSeparator

local Label = class(Control)

function Label:_init(text)
    self._raw = _lib.uiNewLabel(text)
end

function Label:set_Text(text)
    _lib.uiLabelSetText(self._raw, text)
end

function Label:get_Text()
    return _checkcstr(_lib.uiLabelText(self._raw))
end

Label._name = "Label"
M.Label = Label

local Menu = class(Control)

function Menu:_init(name)
    self._raw = _lib.uiNewMenu(name)
end

function Menu:AppendPreferencesItem()
    return _lib.uiMenuAppendPreferencesItem(self._raw)
end

function Menu:AppendAboutItem()
    return _lib.uiMenuAppendAboutItem(self._raw)
end

function Menu:AppendSeparator()
    _lib.uiMenuAppendSeparator(self._raw)
end

function Menu:AppendCheckItem(name)
    return _lib.uiMenuAppendCheckItem(self._raw, name)
end

function Menu:AppendQuitItem()
    return _lib.uiMenuAppendQuitItem(self._raw)
end

function Menu:ItemSetChecked(checked)
    _lib.uiMenuItemSetChecked(self._raw, checked)
end

function Menu:ItemOnClicked(f, data)
    _lib.uiMenuItemOnClicked(self._raw, f, data)
end

function Menu:ItemDisable()
    _lib.uiMenuItemDisable(self._raw)
end

function Menu:ItemChecked()
    return _checkbool(_lib.uiMenuItemChecked(self._raw))
end

function Menu:ItemEnable()
    _lib.uiMenuItemEnable(self._raw)
end

function Menu:AppendItem(name)
    return _lib.uiMenuAppendItem(self._raw, name)
end

Menu._name = "Menu"
M.Menu = Menu

local MultilineEntry = class(Control)

function MultilineEntry:_init()
    self._raw = _lib.uiNewMultilineEntry()
end

function MultilineEntry:set_OnChanged(cb)
    _lib.uiMultilineEntryOnChanged(self._raw, function() return cb() end, nil)
end

function MultilineEntry:set_ReadOnly(readonly)
    _lib.uiMultilineEntrySetReadOnly(self._raw, readonly)
end

function MultilineEntry:get_ReadOnly()
    return _checkbool(_lib.uiMultilineEntryReadOnly(self._raw))
end

function MultilineEntry:set_Text(text)
    _lib.uiMultilineEntrySetText(self._raw, text)
end

function MultilineEntry:Append(text)
    _lib.uiMultilineEntryAppend(self._raw, text)
end

function MultilineEntry:get_Text()
    return _checkcstr(_lib.uiMultilineEntryText(self._raw))
end

MultilineEntry._name = "MultilineEntry"
M.MultilineEntry = MultilineEntry

local NonWrappingMultilineEntry = class(Control)

function NonWrappingMultilineEntry:_init()
    self._raw = _lib.uiNewNonWrappingMultilineEntry()
end

NonWrappingMultilineEntry._name = "NonWrappingMultilineEntry"
M.NonWrappingMultilineEntry = NonWrappingMultilineEntry

local PasswordEntry = class(Control)

function PasswordEntry:_init()
    self._raw = _lib.uiNewPasswordEntry()
end

PasswordEntry._name = "PasswordEntry"
M.PasswordEntry = PasswordEntry

local ProgressBar = class(Control)

function ProgressBar:_init()
    self._raw = _lib.uiNewProgressBar()
end

function ProgressBar:set_Value(n)
    _lib.uiProgressBarSetValue(self._raw, n)
end

function ProgressBar:get_Value()
    return _lib.uiProgressBarValue(self._raw)
end

ProgressBar._name = "ProgressBar"
M.ProgressBar = ProgressBar

local RadioButtons = class(Control)

function RadioButtons:_init()
    self._raw = _lib.uiNewRadioButtons()
end

function RadioButtons:set_OnSelected(cb)
    _lib.uiRadioButtonsOnSelected(self._raw, function() return cb() end, nil)
end

function RadioButtons:set_Selected(n)
    _lib.uiRadioButtonsSetSelected(self._raw, n)
end

function RadioButtons:get_Selected()
    return _lib.uiRadioButtonsSelected(self._raw)
end

function RadioButtons:Append(text)
    _lib.uiRadioButtonsAppend(self._raw, text)
end

RadioButtons._name = "RadioButtons"
M.RadioButtons = RadioButtons

local SearchEntry = class(Control)

function SearchEntry:_init()
    self._raw = _lib.uiNewSearchEntry()
end

SearchEntry._name = "SearchEntry"
M.SearchEntry = SearchEntry

local Slider = class(Control)

function Slider:_init(min, max)
    self._raw = _lib.uiNewSlider(min, max)
end

function Slider:set_OnChanged(cb)
    _lib.uiSliderOnChanged(self._raw, function() return cb() end, nil)
end

function Slider:set_Value(value)
    _lib.uiSliderSetValue(self._raw, value)
end

function Slider:get_Value()
    return _lib.uiSliderValue(self._raw)
end

Slider._name = "Slider"
M.Slider = Slider

local Spinbox = class(Control)

function Spinbox:_init(min, max)
    self._raw = _lib.uiNewSpinbox(min, max)
end

function Spinbox:set_OnChanged(cb)
    _lib.uiSpinboxOnChanged(self._raw, function() return cb() end, nil)
end

function Spinbox:set_Value(value)
    _lib.uiSpinboxSetValue(self._raw, value)
end

function Spinbox:get_Value()
    return _lib.uiSpinboxValue(self._raw)
end

Spinbox._name = "Spinbox"
M.Spinbox = Spinbox

local Tab = class(Control)

function Tab:_init()
    self._raw = _lib.uiNewTab()
end

function Tab:SetMargined(page, margined)
    _lib.uiTabSetMargined(self._raw, page, margined)
end

function Tab:Margined(page)
    return _checkbool(_lib.uiTabMargined(self._raw, page))
end

function Tab:NumPages()
    return _lib.uiTabNumPages(self._raw)
end

function Tab:InsertAt(name, before, c)
    _lib.uiTabInsertAt(self._raw, name, before, ffi.cast("uiControl*", c._raw))
end

function Tab:Delete(index)
    _lib.uiTabDelete(self._raw, index)
end

function Tab:Append(name, c)
    _lib.uiTabAppend(self._raw, name, ffi.cast("uiControl*", c._raw))
end

Tab._name = "Tab"
M.Tab = Tab

local TimePicker = class(Control)

function TimePicker:_init()
    self._raw = _lib.uiNewTimePicker()
end

TimePicker._name = "TimePicker"
M.TimePicker = TimePicker

local VerticalBox = class(Box)

function VerticalBox:_init()
    self._raw = _lib.uiNewVerticalBox()
end

VerticalBox._name = "VerticalBox"
M.VerticalBox = VerticalBox

local VerticalSeparator = class(Control)

function VerticalSeparator:_init()
    self._raw = _lib.uiNewVerticalSeparator()
end

VerticalSeparator._name = "VerticalSeparator"
M.VerticalSeparator = VerticalSeparator

local Window = class(Control)

function Window:_init(title, width, height, hasMenubar)
    self._raw = _lib.uiNewWindow(title, width, height, hasMenubar)
end

function Window:set_OnClosing(cb)
    _lib.uiWindowOnClosing(self._raw, function() return cb() end, nil)
end

function Window:set_OnContentSizeChanged(cb)
    _lib.uiWindowOnContentSizeChanged(self._raw, function() return cb() end, nil)
end

function Window:set_OnPositionChanged(cb)
    _lib.uiWindowOnPositionChanged(self._raw, function() return cb() end, nil)
end

function Window:SetContentSize(width, height)
    _lib.uiWindowSetContentSize(self._raw, width, height)
end

function Window:set_Fullscreen(fullscreen)
    _lib.uiWindowSetFullscreen(self._raw, fullscreen)
end

function Window:set_Borderless(borderless)
    _lib.uiWindowSetBorderless(self._raw, borderless)
end

function Window:set_Margined(margined)
    _lib.uiWindowSetMargined(self._raw, margined)
end

function Window:SetPosition(x, y)
    _lib.uiWindowSetPosition(self._raw, x, y)
end

function Window:ContentSize(width, height)
    _lib.uiWindowContentSize(self._raw, width, height)
end

function Window:get_Borderless()
    return _checkbool(_lib.uiWindowBorderless(self._raw))
end

function Window:get_Fullscreen()
    return _checkbool(_lib.uiWindowFullscreen(self._raw))
end

function Window:set_Title(title)
    _lib.uiWindowSetTitle(self._raw, title)
end

function Window:get_Margined()
    return _checkbool(_lib.uiWindowMargined(self._raw))
end

function Window:set_Child(child)
    _lib.uiWindowSetChild(self._raw, ffi.cast("uiControl*", child._raw))
end

function Window:Position(x, y)
    _lib.uiWindowPosition(self._raw, x, y)
end

function Window:Center()
    _lib.uiWindowCenter(self._raw)
end

function Window:get_Title()
    return _checkcstr(_lib.uiWindowTitle(self._raw))
end

Window._name = "Window"
M.Window = Window

function M.Init()
    local err = _lib.uiInit(ffi.new("uiInitOptions[1]"))
    if err ~= nil then error(ffi.string(err)) end
end

function M.MsgBox(parent, title, description)
    _lib.uiMsgBox(ffi.cast("uiWindow*", parent._raw), title, description)
end

function M.MsgBoxError(parent, title, description)
    _lib.uiMsgBoxError(ffi.cast("uiWindow*", parent._raw), title, description)
end

function M.OpenFile(parent)
    return _checkcstr(_lib.uiOpenFile(ffi.cast("uiWindow*", parent._raw)))
end

function M.SaveFile(parent)
    return _checkcstr(_lib.uiSaveFile(ffi.cast("uiWindow*", parent._raw)))
end

function M.Main()
    _lib.uiMain()
end

function M.MainStep(wait)
    return _checkbool(_lib.uiMainStep(wait))
end

function M.MainSteps()
    _lib.uiMainSteps()
end

function M.set_OnShouldQuit(f, data)
    _lib.uiOnShouldQuit(f, data)
end

function M.QueueMain(f, data)
    _lib.uiQueueMain(f, data)
end

function M.Quit()
    _lib.uiQuit()
end

function M.Uninit()
    _lib.uiUninit()
end

return M
