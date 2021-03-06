#ifndef SCREEN_TEXT_ENTRY_H
#define SCREEN_TEXT_ENTRY_H

#include "Etterna/Actor/Base/BitmapText.h"
#include "Etterna/Models/Misc/InputEventPlus.h"
#include "RageUtil/Sound/RageSound.h"
#include "ScreenWithMenuElements.h"
#include "Etterna/Models/Misc/ThemeMetric.h"

/** @brief The list of possible keyboard rows. */
enum KeyboardRow
{
	R1,
	R2,
	R3,
	R4,
	R5,
	R6,
	R7,
	KEYBOARD_ROW_SPECIAL,
	NUM_KeyboardRow,
	KeyboardRow_Invalid
};
/** @brief A special foreach loop for the KeyboardRow enum. */
#define FOREACH_KeyboardRow(i) FOREACH_ENUM(KeyboardRow, i)
/** @brief The maximum number of keys per row. */
const int KEYS_PER_ROW = 13;
/** @brief The list of very special keys inside some rows. */
enum KeyboardRowSpecialKey
{
	SPACEBAR = 2,  /**< The space bar key. */
	BACKSPACE = 5, /**< The backspace key. */
	CANCEL = 8,
	DONE = 11
};

/** @brief Displays a text entry box over the top of another screen. */
class ScreenTextEntry : public ScreenWithMenuElements
{
  public:
	void SetTextEntrySettings(
	  RString sQuestion,
	  RString sInitialAnswer,
	  int iMaxInputLength,
	  bool (*Validate)(const RString& sAnswer, RString& sErrorOut) = NULL,
	  void (*OnOK)(const RString& sAnswer) = NULL,
	  void (*OnCancel)() = NULL,
	  bool bPassword = false,
	  bool (*ValidateAppend)(const RString& sAnswerBeforeChar,
							 const RString& sAppend) = NULL,
	  RString (*FormatAnswerForDisplay)(const RString& sAnswer) = NULL);
	void SetTextEntrySettings(
	  RString sQuestion,
	  RString sInitialAnswer,
	  int iMaxInputLength,
	  LuaReference,
	  LuaReference,
	  LuaReference,
	  LuaReference,
	  LuaReference,
	  bool (*Validate)(const RString& sAnswer, RString& sErrorOut) = NULL,
	  void (*OnOK)(const RString& sAnswer) = NULL,
	  void (*OnCancel)() = NULL,
	  bool bPassword = false,
	  bool (*ValidateAppend)(const RString& sAnswerBeforeChar,
							 const RString& sAppend) = NULL,
	  RString (*FormatAnswerForDisplay)(const RString& sAnswer) = NULL);
	static void TextEntry(
	  ScreenMessage smSendOnPop,
	  RString sQuestion,
	  RString sInitialAnswer,
	  int iMaxInputLength,
	  bool (*Validate)(const RString& sAnswer, RString& sErrorOut) = NULL,
	  void (*OnOK)(const RString& sAnswer) = NULL,
	  void (*OnCancel)() = NULL,
	  bool bPassword = false,
	  bool (*ValidateAppend)(const RString& sAnswerBeforeChar,
							 const RString& sAppend) = NULL,
	  RString (*FormatAnswerForDisplay)(const RString& sAnswer) = NULL);
	static void Password(ScreenMessage smSendOnPop,
						 const RString& sQuestion,
						 void (*OnOK)(const RString& sPassword) = NULL,
						 void (*OnCancel)() = NULL)
	{
		TextEntry(smSendOnPop, sQuestion, "", 255, NULL, OnOK, OnCancel, true);
	}

	struct TextEntrySettings
	{
		TextEntrySettings()
		  : smSendOnPop()
		  , sQuestion("")
		  , sInitialAnswer("")
		  , Validate()
		  , OnOK()
		  , OnCancel()
		  , ValidateAppend()
		  , FormatAnswerForDisplay()
		{
		}
		ScreenMessage smSendOnPop;
		RString sQuestion;
		RString sInitialAnswer;
		int iMaxInputLength{ 0 };
		/** @brief Is there a password involved with this setting?
		 *
		 * This parameter doesn't have to be used. */
		bool bPassword{ false };
		LuaReference Validate; // (RString sAnswer, RString sErrorOut; optional)
		LuaReference OnOK;	 // (RString sAnswer; optional)
		LuaReference OnCancel; // (optional)
		LuaReference ValidateAppend; // (RString sAnswerBeforeChar, RString
									 // sAppend; optional)
		LuaReference FormatAnswerForDisplay; // (RString sAnswer; optional)

		// see BitmapText.cpp Attribute::FromStack()  and
		// OptionRowHandler.cpp LoadInternal() for ideas on how to implement the
		// main part, and ImportOption() from OptionRowHandler.cpp for
		// functions.
		void FromStack(lua_State* L);
	};
	void LoadFromTextEntrySettings(const TextEntrySettings& settings);

	static bool FloatValidate(const RString& sAnswer, RString& sErrorOut);
	static bool IntValidate(const RString& sAnswer, RString& sErrorOut);

	RString sQuestion{ "" };
	RString sInitialAnswer{ "" };
	int iMaxInputLength{ 0 };
	bool (*pValidate)(const RString& sAnswer, RString& sErrorOut){ NULL };
	void (*pOnOK)(const RString& sAnswer){ NULL };
	void (*pOnCancel)(){ NULL };
	bool bPassword{ false };
	bool (*pValidateAppend)(const RString& sAnswerBeforeChar,
							const RString& sAppend){ NULL };
	RString (*pFormatAnswerForDisplay)(const RString& sAnswer){ NULL };

	// Lua bridge
	LuaReference ValidateFunc;
	LuaReference OnOKFunc;
	LuaReference OnCancelFunc;
	LuaReference ValidateAppendFunc;
	LuaReference FormatAnswerForDisplayFunc;

	void Init() override;
	void BeginScreen() override;

	void Update(float fDelta) override;
	bool Input(const InputEventPlus& input) override;

	static RString s_sLastAnswer;
	static bool s_bCancelledLast;

	// Lua
	void PushSelf(lua_State* L) override;

  protected:
	void TryAppendToAnswer(const RString& s);
	void BackspaceInAnswer();
	virtual void TextEnteredDirectly() {}

	virtual void End(bool bCancelled);

  private:
	bool MenuStart(const InputEventPlus& input) override;
	bool MenuBack(const InputEventPlus& input) override;

	void UpdateAnswerText();

	wstring m_sAnswer;
	bool m_bShowAnswerCaret = false;
	// todo: allow Left/Right to change caret location -aj
	// int			m_iCaretLocation;

	BitmapText m_textQuestion;
	BitmapText m_textAnswer;

	RageSound m_sndType;
	RageSound m_sndBackspace;

	RageTimer m_timerToggleCursor;
};

/** @brief Displays a text entry box and keyboard over the top of another
 * screen. */
class ScreenTextEntryVisual : public ScreenTextEntry
{
  public:
	~ScreenTextEntryVisual() override;
	void Init() override;
	void BeginScreen() override;

  protected:
	void MoveX(int iDir);
	void MoveY(int iDir);
	void PositionCursor();

	void TextEnteredDirectly() override;

	bool MenuLeft(const InputEventPlus& input) override;
	bool MenuRight(const InputEventPlus& input) override;
	bool MenuUp(const InputEventPlus& input) override;
	bool MenuDown(const InputEventPlus& input) override;

	bool MenuStart(const InputEventPlus& input) override;

	int m_iFocusX;
	KeyboardRow m_iFocusY;

	AutoActor m_sprCursor;
	BitmapText* m_ptextKeys[NUM_KeyboardRow][KEYS_PER_ROW];

	RageSound m_sndChange;

	ThemeMetric<float> ROW_START_X;
	ThemeMetric<float> ROW_START_Y;
	ThemeMetric<float> ROW_END_X;
	ThemeMetric<float> ROW_END_Y;
};

#endif
