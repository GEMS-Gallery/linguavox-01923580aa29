import Bool "mo:base/Bool";
import Nat "mo:base/Nat";

import Text "mo:base/Text";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import Nat32 "mo:base/Nat32";
import Iter "mo:base/Iter";

actor {
  type TranslationEntry = {
    original: Text;
    translated: Text;
    targetLanguage: Text;
  };

  type HttpHeader = {
    name : Text;
    value : Text;
  };

  type HttpResponsePayload = {
    status : Nat;
    headers : [HttpHeader];
    body : Blob;
  };

  type CanisterHttpRequestArgs = {
    url : Text;
    max_response_bytes : ?Nat64;
    headers : [HttpHeader];
    body : ?[Nat8];
    method : {#get; #post; #head};
    transform : ?{
      function : shared query TransformArgs -> async HttpResponsePayload;
      context : Blob;
    };
  };

  type TransformArgs = {
    response : HttpResponsePayload;
    context : Blob;
  };

  let IC = actor "aaaaa-aa" : actor {
    http_request : CanisterHttpRequestArgs -> async HttpResponsePayload;
  };

  stable var translationHistory : [TranslationEntry] = [];

  public func translate(text: Text, targetLang: Text) : async Text {
    let encodedText = encodeURIComponent(text);
    let url = "https://api.mymemory.translated.net/get?q=" # encodedText # "&langpair=en|" # targetLang;

    let request : CanisterHttpRequestArgs = {
      url = url;
      max_response_bytes = null;
      headers = [];
      body = null;
      method = #get;
      transform = null;
    };

    try {
      let response = await IC.http_request(request);
      let responseBody = Text.decodeUtf8(response.body);
      
      switch (responseBody) {
        case (?decodedBody) {
          let translatedText = parseTranslation(decodedBody);
          
          // Add to history
          let entry : TranslationEntry = {
            original = text;
            translated = translatedText;
            targetLanguage = targetLang;
          };
          translationHistory := Array.append(translationHistory, [entry]);

          translatedText
        };
        case null {
          Debug.print("Error: Unable to decode response body");
          "Translation error occurred"
        };
      };
    } catch (error) {
      Debug.print("Error: " # Error.message(error));
      "Translation error occurred"
    };
  };

  private func parseTranslation(body: Text) : Text {
    // Simple parsing, assuming the response is in JSON format
    let startPattern = "\"translatedText\":\"";
    let startIndex = textFind(body, startPattern);
    switch (startIndex) {
      case (?start) {
        let remaining = Text.trimStart(body, #text(textSlice(body, 0, start + Text.size(startPattern))));
        let endIndex = textFind(remaining, "\"");
        switch (endIndex) {
          case (?end) {
            textSlice(remaining, 0, end)
          };
          case null { "Parsing error" };
        };
      };
      case null { "Parsing error" };
    };
  };

  private func textFind(text: Text, pattern: Text) : ?Nat {
    let textSize = Text.size(text);
    let patternSize = Text.size(pattern);

    func check(i: Nat) : ?Nat {
      if (i + patternSize > textSize) {
        null
      } else if (Text.equal(textSlice(text, i, i + patternSize), pattern)) {
        ?i
      } else {
        check(i + 1)
      };
    };

    check(0)
  };

  private func textSlice(t: Text, start: Nat, end: Nat) : Text {
    let chars = Iter.toArray(t.chars());
    let size = chars.size();
    if (start >= size) { return ""; };
    let realEnd = if (end > size) { size } else { end };
    let length = realEnd - start;
    Text.fromIter(Array.init<Char>(length, chars[start]).vals())
  };

  public query func getTranslationHistory() : async [TranslationEntry] {
    translationHistory
  };

  // Helper function to encode URI components
  private func encodeURIComponent(str: Text) : Text {
    let unreserved = "-_.!~*'()";
    let hexChars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];
    var result = "";
    for (char in str.chars()) {
      if (isAlphanumeric(char) or Text.contains(unreserved, #char char)) {
        result #= Text.fromChar(char);
      } else {
        let byte = Nat8.fromNat(Nat32.toNat(Char.toNat32(char)));
        result #= "%" # hexChars[Nat8.toNat(byte / 16)] # hexChars[Nat8.toNat(byte % 16)];
      };
    };
    result
  };

  // Helper function to check if a character is alphanumeric
  private func isAlphanumeric(char: Char) : Bool {
    Char.isAlphabetic(char) or Char.isDigit(char)
  };

  system func preupgrade() {
    // No need to do anything as we're using stable storage
  };

  system func postupgrade() {
    // No need to do anything as we're using stable storage
  };
}
