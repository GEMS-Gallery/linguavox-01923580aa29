export const idlFactory = ({ IDL }) => {
  const TranslationEntry = IDL.Record({
    'translated' : IDL.Text,
    'targetLanguage' : IDL.Text,
    'original' : IDL.Text,
  });
  return IDL.Service({
    'getTranslationHistory' : IDL.Func(
        [],
        [IDL.Vec(TranslationEntry)],
        ['query'],
      ),
    'translate' : IDL.Func([IDL.Text, IDL.Text], [IDL.Text], []),
  });
};
export const init = ({ IDL }) => { return []; };
