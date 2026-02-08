{\rtf1\ansi\ansicpg1252\cocoartf2867
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\froman\fcharset0 Times-Roman;\f1\fmodern\fcharset0 Courier;\f2\froman\fcharset0 Times-Bold;
\f3\fswiss\fcharset0 Helvetica-Bold;\f4\fswiss\fcharset0 Helvetica;\f5\fnil\fcharset0 .SFNS-Regular;
}
{\colortbl;\red255\green255\blue255;\red0\green0\blue0;\red0\green0\blue0;}
{\*\expandedcolortbl;;\cssrgb\c0\c0\c0;\cssrgb\c0\c0\c0\c84706\cname labelColor;}
{\*\listtable{\list\listtemplateid1\listhybrid{\listlevel\levelnfc0\levelnfcn0\leveljc0\leveljcn0\levelfollow0\levelstartat1\levelspace360\levelindent0{\*\levelmarker \{decimal\}}{\leveltext\leveltemplateid1\'01\'00;}{\levelnumbers\'01;}\fi-360\li720\lin720 }{\listname ;}\listid1}
{\list\listtemplateid2\listhybrid{\listlevel\levelnfc23\levelnfcn23\leveljc0\leveljcn0\levelfollow0\levelstartat0\levelspace360\levelindent0{\*\levelmarker \{disc\}}{\leveltext\leveltemplateid101\'01\uc0\u8226 ;}{\levelnumbers;}\fi-360\li720\lin720 }{\listname ;}\listid2}
{\list\listtemplateid3\listhybrid{\listlevel\levelnfc23\levelnfcn23\leveljc0\leveljcn0\levelfollow0\levelstartat0\levelspace360\levelindent0{\*\levelmarker \{disc\}}{\leveltext\leveltemplateid201\'01\uc0\u8226 ;}{\levelnumbers;}\fi-360\li720\lin720 }{\listname ;}\listid3}
{\list\listtemplateid4\listhybrid{\listlevel\levelnfc23\levelnfcn23\leveljc0\leveljcn0\levelfollow0\levelstartat0\levelspace360\levelindent0{\*\levelmarker \{disc\}}{\leveltext\leveltemplateid301\'01\uc0\u8226 ;}{\levelnumbers;}\fi-360\li720\lin720 }{\listname ;}\listid4}}
{\*\listoverridetable{\listoverride\listid1\listoverridecount0\ls1}{\listoverride\listid2\listoverridecount0\ls2}{\listoverride\listid3\listoverridecount0\ls3}{\listoverride\listid4\listoverridecount0\ls4}}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf0 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 "Please update the 
\f1\fs26 \strokec2 EpisodePlayerView
\f0\fs24 \strokec2  using this 3-section architecture. Specifically, ensure that the 
\f2\b \strokec2 Metadata and Playback Controls
\f0\b0 \strokec2  are placed in a fixed 
\f1\fs26 \strokec2 VStack
\f0\fs24 \strokec2  at the bottom of a 
\f1\fs26 \strokec2 ZStack
\f0\fs24 \strokec2 . This footer must use an 
\f1\fs26 \strokec2 .ultraThinMaterial
\f0\fs24 \strokec2  background. Refer to the provided 
\f1\fs26 \strokec2 NotesSegmentView
\f0\fs24 \strokec2  and 
\f1\fs26 \strokec2 InfoSegmentView
\f0\fs24 \strokec2  code to ensure the 'Add Note' button correctly switches between the fixed footer and the scrollable list depending on the active segment."
\f2\b\fs48 \strokec2 \
\
\pard\pardeftab720\sa321\partightenfactor0
\cf0 Technical Specification: EpisodePlayerView (iOS 26)\
\pard\pardeftab720\sa298\partightenfactor0

\fs36 \cf0 1. Architectural Strategy: Layered ZStack\
\pard\pardeftab720\sa240\partightenfactor0

\f0\b0\fs24 \cf0 To match the Figma designs, the view must be structured as a 
\f1\fs26 ZStack
\f0\fs24 . This allows the 
\f2\b Header
\f0\b0  and 
\f2\b Footer
\f0\b0  to remain stationary while the 
\f2\b Mid-Section
\f0\b0  content scrolls behind the translucent "Glass" layers.\
\pard\pardeftab720\sa280\partightenfactor0

\f2\b\fs28 \cf0 The 3-Section Breakdown\
\pard\tx220\tx720\pardeftab720\li720\fi-720\sa240\partightenfactor0
\ls1\ilvl0
\fs24 \cf0 \kerning1\expnd0\expndtw0 \outl0\strokewidth0 {\listtext	1	}\expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 Header (Fixed):
\f0\b0  Contains the drag handle and dismiss button.\
\ls1\ilvl0
\f2\b \kerning1\expnd0\expndtw0 \outl0\strokewidth0 {\listtext	2	}\expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 Mid-Section (Scrollable):
\f0\b0  The dynamic content area (Listening, Notes, Info) that reacts to the Segmented Control.\
\ls1\ilvl0
\f2\b \kerning1\expnd0\expndtw0 \outl0\strokewidth0 {\listtext	3	}\expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 Footer (Fixed):
\f0\b0  The "Now Playing" metadata, Scrubber, Playback Controls, and "Add Note" button.\
\pard\pardeftab720\partightenfactor0
\cf0 \strokec2 2. Structural Audit: Discrepancy Reconciliation\
\

\itap1\trowd \taflags0 \trgaph108\trleft-108 \tamarb640 \trbrdrt\brdrnil \trbrdrl\brdrnil \trbrdrr\brdrnil 
\clvertalc \clshdrawnil \clwWidth2267\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx2880
\clvertalc \clshdrawnil \clwWidth3961\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx5760
\clvertalc \clshdrawnil \clwWidth8364\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx8640
\pard\intbl\itap1\pardeftab720\partightenfactor0

\f3\b \cf0 \strokec2 Feature
\f4\b0 \cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0

\f3\b \cf0 Current Implementation (Actual)
\f4\b0 \cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0

\f3\b \cf0 Figma Target (iOS 26 Standard)
\f4\b0 \cell \row

\itap1\trowd \taflags0 \trgaph108\trleft-108 \tamarb640 \trbrdrl\brdrnil \trbrdrr\brdrnil 
\clvertalc \clshdrawnil \clwWidth2267\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx2880
\clvertalc \clshdrawnil \clwWidth3961\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx5760
\clvertalc \clshdrawnil \clwWidth8364\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx8640
\pard\intbl\itap1\pardeftab720\partightenfactor0

\f3\b \cf0 Control Persistence
\f4\b0 \cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0
\cf0 Controls scroll away with the content.\cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0
\cf0 Controls are 
\f3\b fixed
\f4\b0  in a bottom Glass deck.\cell \row

\itap1\trowd \taflags0 \trgaph108\trleft-108 \tamarb640 \trbrdrl\brdrnil \trbrdrr\brdrnil 
\clvertalc \clshdrawnil \clwWidth2267\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx2880
\clvertalc \clshdrawnil \clwWidth3961\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx5760
\clvertalc \clshdrawnil \clwWidth8364\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx8640
\pard\intbl\itap1\pardeftab720\partightenfactor0

\f3\b \cf0 "Add Note" CTA
\f4\b0 \cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0
\cf0 Full-width button in the scroll view.\cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0
\cf0 Compact button integrated above the scrubber (Listening) or top of list (Notes).\cell \row

\itap1\trowd \taflags0 \trgaph108\trleft-108 \tamarb640 \trbrdrl\brdrnil \trbrdrr\brdrnil 
\clvertalc \clshdrawnil \clwWidth2267\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx2880
\clvertalc \clshdrawnil \clwWidth3961\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx5760
\clvertalc \clshdrawnil \clwWidth8364\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx8640
\pard\intbl\itap1\pardeftab720\partightenfactor0

\f3\b \cf0 Layout Layering
\f4\b0 \cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0
\cf0 Single vertical VStack.\cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0
\cf0 Layered ZStack with ultraThinMaterial blurring content behind controls.\cell \row

\itap1\trowd \taflags0 \trgaph108\trleft-108 \tamarb640 \trbrdrl\brdrnil \trbrdrt\brdrnil \trbrdrr\brdrnil 
\clvertalc \clshdrawnil \clwWidth2267\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx2880
\clvertalc \clshdrawnil \clwWidth3961\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx5760
\clvertalc \clshdrawnil \clwWidth8364\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx8640
\pard\intbl\itap1\pardeftab720\partightenfactor0

\f3\b \cf0 Artwork Transition
\f4\b0 \cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0
\cf0 Static or simple slide.\cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0

\f3\b \cf0 MatchedGeometryEffect
\f4\b0  from mini-player to hero image.\cell \lastrow\row
\pard\pardeftab720\partightenfactor0

\f0 \cf0 \strokec2 \
3. Implementation Code\
\
Root View Structure\
\
struct EpisodePlayerView: View \{\
    @State private var selectedSegment = 0\
    @Namespace var playerAnimation\
    \
    var body: some View \{\
        ZStack(alignment: .bottom) \{\
            // LAYER 1: The Scrollable Content (Mid-Section)\
            ScrollView \{\
                VStack(spacing: 24) \{\
                    Spacer(minLength: 60) // Space for fixed header\
                    \
                    SegmentedPicker(selection: $selectedSegment)\
                    \
                    switch selectedSegment \{\
                    case 0: ListeningSegmentView(namespace: playerAnimation)\
                    case 1: NotesSegmentView()\
                    case 2: InfoSegmentView()\
                    default: EmptyView()\
                    \}\
                \}\
                // Crucial: Reserve space so the list can clear the fixed footer\
                .padding(.bottom, 220) \
            \}\
            .scrollEdgeEffectStyle(.soft, for: .bottom) // iOS 26 Liquid Glass effect\
\
            // LAYER 2: The Persistent Footer (Section 3)\
            VStack(spacing: 0) \{\
                // Metadata & Scrubber\
                PlayerControlDeck(selectedSegment: selectedSegment)\
                    .background(.ultraThinMaterial) // Native "Glass"\
                    .glassEffect(.regular.interactive()) // iOS 26 interaction\
            \}\
            .ignoresSafeArea(edges: .bottom)\
        \}\
    \}\
\}\
\
\pard\pardeftab720\sa280\partightenfactor0

\f2\b\fs28 \cf0 \strokec2 The "Add Note" Logic\
\pard\pardeftab720\sa240\partightenfactor0

\f0\b0\fs24 \cf0 The position of the 
\f2\b Add Note
\f0\b0  button changes based on the segment to match Figma\'92s context-aware design:\
\
struct PlayerControlDeck: View \{\
    let selectedSegment: Int\
    \
    var body: some View \{\
        VStack(spacing: 16) \{\
            // Metadata: Title and Podcast (Always visible)\
            EpisodeMetadataView()\
            \
            // Contextual CTA: Only stays fixed in the "Listening" view\
            if selectedSegment == 0 \{\
                Button("Add note at current time") \{ /* Action */ \}\
                    .buttonStyle(.glassProminent) // iOS 26 style\
            \}\
            \
            ScrubberView()\
            PlaybackControlsView()\
            UtilityToolbar() // 1.0x, Share, More\
        \}\
        .padding()\
    \}\
\}\
\
\pard\pardeftab720\sa280\partightenfactor0

\f2\b\fs28 \cf0 The "Add Note" Logic\
\pard\pardeftab720\sa240\partightenfactor0

\f0\b0\fs24 \cf0 The position of the 
\f2\b Add Note
\f0\b0  button changes based on the segment to match Figma\'92s context-aware design:\
\
struct PlayerControlDeck: View \{\
    let selectedSegment: Int\
    \
    var body: some View \{\
        VStack(spacing: 16) \{\
            // Metadata: Title and Podcast (Always visible)\
            EpisodeMetadataView()\
            \
            // Contextual CTA: Only stays fixed in the "Listening" view\
            if selectedSegment == 0 \{\
                Button("Add note at current time") \{ /* Action */ \}\
                    .buttonStyle(.glassProminent) // iOS 26 style\
            \}\
            \
            ScrubberView()\
            PlaybackControlsView()\
            UtilityToolbar() // 1.0x, Share, More\
        \}\
        .padding()\
    \}\
\}\
\
\pard\pardeftab720\sa298\partightenfactor0

\f2\b\fs36 \cf0 4. Key iOS 26 Styling Checklist\
\pard\tx220\tx720\pardeftab720\li720\fi-720\sa240\partightenfactor0
\ls2\ilvl0
\fs24 \cf0 \kerning1\expnd0\expndtw0 \outl0\strokewidth0 {\listtext	\uc0\u8226 	}\expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 Safe Area Insets:
\f0\b0  Use 
\f1\fs26 .safeAreaInset(edge: .bottom)
\f0\fs24  instead of manual padding if you want the ScrollView to handle the footer height dynamically.\
\ls2\ilvl0
\f2\b \kerning1\expnd0\expndtw0 \outl0\strokewidth0 {\listtext	\uc0\u8226 	}\expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 Material Selection:
\f0\b0  Use 
\f1\fs26 .ultraThinMaterial
\f0\fs24  for the footer background to ensure the "Liquid Glass" light-bending effect occurs as content scrolls beneath it.\
\ls2\ilvl0
\f2\b \kerning1\expnd0\expndtw0 \outl0\strokewidth0 {\listtext	\uc0\u8226 	}\expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 Matched Geometry:
\f0\b0  Ensure the 
\f1\fs26 namespace
\f0\fs24  is passed to the 
\f1\fs26 ListeningSegmentView
\f0\fs24  so the artwork zooms seamlessly from the Tab Bar accessory.\
\pard\tx220\tx720\pardeftab720\li720\fi-720\sa240\partightenfactor0
\cf0 \
\pard\pardeftab720\partightenfactor0
\ls3\ilvl0\cf0 \kerning1\expnd0\expndtw0 \outl0\strokewidth0 {\listtext	\uc0\u8226 	}\expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 5. Segment Component Implementation\
\ls3\ilvl0\kerning1\expnd0\expndtw0 \outl0\strokewidth0 \
\ls3\ilvl0
\f5\fs52 \cf3 {\listtext	\'95	}NotesSegmentView (Segment 2)  This segment implements the "Timeline" list seen in the Figma Notes design. It handles the "Add Note" button as a scrollable element rather than a fixed one in this context.\
\
{\listtext	\'95	}struct NotesSegmentView: View \{\
{\listtext	\'95	}    var body: some View \{\
{\listtext	\'95	}        VStack(alignment: .leading, spacing: 20) \{\
{\listtext	\'95	}            // In the Notes segment, the button scrolls WITH the list\
{\listtext	\'95	}            Button(action: \{\}) \{\
{\listtext	\'95	}                Label("Add note at current time", systemImage: "plus.circle.fill")\
{\listtext	\'95	}                    .frame(maxWidth: .infinity)\
{\listtext	\'95	}                    .padding()\
{\listtext	\'95	}                    .background(Color.mintAccent.opacity(0.15))\
{\listtext	\'95	}                    .cornerRadius(12)\
{\listtext	\'95	}            \}\
{\listtext	\'95	}            .padding(.horizontal)\
\
{\listtext	\'95	}            // Timeline List\
{\listtext	\'95	}            VStack(spacing: 0) \{\
{\listtext	\'95	}                ForEach(0..<5) \{ index in\
{\listtext	\'95	}                    NoteRow(timestamp: "12:45", text: "Discussion about the architectural shifts in Fresno's urban planning.")\
{\listtext	\'95	}                \}\
{\listtext	\'95	}            \}\
{\listtext	\'95	}        \}\
{\listtext	\'95	}    \}\
{\listtext	\'95	}\}\
\
{\listtext	\'95	}struct NoteRow: View \{\
{\listtext	\'95	}    let timestamp: String\
{\listtext	\'95	}    let text: String\
{\listtext	\'95	}    \
{\listtext	\'95	}    var body: some View \{\
{\listtext	\'95	}        HStack(alignment: .top, spacing: 16) \{\
{\listtext	\'95	}            Text(timestamp)\
{\listtext	\'95	}                .font(.caption.monospacedDigit())\
{\listtext	\'95	}                .foregroundColor(.mintAccent)\
{\listtext	\'95	}                .padding(.top, 4)\
{\listtext	\'95	}            \
{\listtext	\'95	}            VStack(alignment: .leading, spacing: 4) \{\
{\listtext	\'95	}                Text(text)\
{\listtext	\'95	}                    .font(.subheadline)\
{\listtext	\'95	}                    .lineLimit(3)\
{\listtext	\'95	}                Divider().padding(.top, 8)\
{\listtext	\'95	}            \}\
{\listtext	\'95	}        \}\
{\listtext	\'95	}        .padding(.horizontal)\
{\listtext	\'95	}        .padding(.vertical, 8)\
{\listtext	\'95	}    \}\
{\listtext	\'95	}\}\
\
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf0 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 \
\
\pard\pardeftab720\sa280\partightenfactor0
\ls4\ilvl0
\f2\b\fs28 \cf0 \strokec2 {\listtext	\'95	}InfoSegmentView (Segment 3)\
\ls4\ilvl0
\f0\b0\fs24 {\listtext	\'95	}This segment handles the long-form episode description as seen in the Figma Episode Info design.\
\pard\pardeftab720\partightenfactor0
\cf0 \strokec2 struct InfoSegmentView: View \{\
    var body: some View \{\
        VStack(alignment: .leading, spacing: 16) \{\
            Text("About this Episode")\
                .font(.headline)\
            \
            Text("In this episode, we dive deep into the cultural evolution of Fresno in 2026. We explore how the new 'Liquid Glass' aesthetic has moved from software into physical architecture...")\
                .font(.body)\
                .foregroundColor(.secondary)\
            \
            // Additional Metadata\
            VStack(alignment: .leading, spacing: 8) \{\
                DetailRow(label: "Released", value: "Feb 7, 2026")\
                DetailRow(label: "Duration", value: "45 min")\
                DetailRow(label: "Size", value: "62 MB")\
            \}\
            .padding(.top)\
        \}\
        .padding(.horizontal)\
    \}\
\}\kerning1\expnd0\expndtw0 \outl0\strokewidth0 \
\
\pard\pardeftab720\partightenfactor0
\cf0 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 6. Final Reconciliation Checklist for the Assistant\
\

\itap1\trowd \taflags0 \trgaph108\trleft-108 \tamarb640 \trbrdrt\brdrnil \trbrdrl\brdrnil \trbrdrr\brdrnil 
\clvertalc \clshdrawnil \clwWidth2227\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx4320
\clvertalc \clshdrawnil \clwWidth12509\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx8640
\pard\intbl\itap1\pardeftab720\partightenfactor0

\f3\b \cf0 \strokec2 Discrepancy Found
\f4\b0 \cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0

\f3\b \cf0 Fix Applied
\f4\b0 \cell \row

\itap1\trowd \taflags0 \trgaph108\trleft-108 \tamarb640 \trbrdrl\brdrnil \trbrdrr\brdrnil 
\clvertalc \clshdrawnil \clwWidth2227\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx4320
\clvertalc \clshdrawnil \clwWidth12509\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx8640
\pard\intbl\itap1\pardeftab720\partightenfactor0

\f3\b \cf0 Scrolling Controls
\f4\b0 \cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0
\cf0 Moved PlaybackControls to a fixed footer inside a ZStack.\cell \row

\itap1\trowd \taflags0 \trgaph108\trleft-108 \tamarb640 \trbrdrl\brdrnil \trbrdrr\brdrnil 
\clvertalc \clshdrawnil \clwWidth2227\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx4320
\clvertalc \clshdrawnil \clwWidth12509\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx8640
\pard\intbl\itap1\pardeftab720\partightenfactor0

\f3\b \cf0 Full-Width CTA
\f4\b0 \cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0
\cf0 Changed "Add Note" to context-aware positioning (Fixed in Listening, Scrollable in Notes).\cell \row

\itap1\trowd \taflags0 \trgaph108\trleft-108 \tamarb640 \trbrdrl\brdrnil \trbrdrr\brdrnil 
\clvertalc \clshdrawnil \clwWidth2227\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx4320
\clvertalc \clshdrawnil \clwWidth12509\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx8640
\pard\intbl\itap1\pardeftab720\partightenfactor0

\f3\b \cf0 Metadata Visibility
\f4\b0 \cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0
\cf0 Episode Title and Podcast Name moved into the fixed footer so they never scroll away.\cell \row

\itap1\trowd \taflags0 \trgaph108\trleft-108 \tamarb640 \trbrdrl\brdrnil \trbrdrt\brdrnil \trbrdrr\brdrnil 
\clvertalc \clshdrawnil \clwWidth2227\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx4320
\clvertalc \clshdrawnil \clwWidth12509\clftsWidth3 \clmart10 \clmarl10 \clmarb10 \clmarr10 \clbrdrt\brdrs\brdrw20\brdrcf2 \clbrdrl\brdrs\brdrw20\brdrcf2 \clbrdrb\brdrs\brdrw20\brdrcf2 \clbrdrr\brdrs\brdrw20\brdrcf2 \clpadt20 \clpadl20 \clpadb20 \clpadr20 \gaph\cellx8640
\pard\intbl\itap1\pardeftab720\partightenfactor0

\f3\b \cf0 Safe Areas
\f4\b0 \cell 
\pard\intbl\itap1\pardeftab720\partightenfactor0
\cf0 Applied .padding(.bottom, 220) to the ScrollView content to prevent the fixed Glass deck from hiding the last list items.\
\cell \lastrow\row
\pard\pardeftab720\partightenfactor0

\f0 \cf0 \strokec2 \
For reference, the first tab\'92s Figma design is: https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1878-4405&t=n2ncIH2GVubfzvEj-4\
\
The second tab (Notes)\'92s Figma design is: https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1878-5413&t=n2ncIH2GVubfzvEj-4\
\
The third tab (Episode info)\'92s Figma design is: https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1878-5414&t=n2ncIH2GVubfzvEj-4}