// SPDX-License-Identifier: The Unlicense
/// @author Modified from Area-Technology (https://github.com/Area-Technology/shields-contracts/tree/main/contracts/SVGs)

pragma solidity ^0.8.13;

import '../../../interfaces/IFieldSVGs.sol';
import '../../../interfaces/ICategories.sol';
import '../../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs16 is IFieldSVGs, ICategories {
	using HexStrings for uint24;

	function field_224(uint24[4] memory colors) public pure returns (FieldData memory) {
		return
			FieldData(
				'Flex Checky',
				FieldCategories.OLYMPIC,
				string(
					abi.encodePacked(
						'<defs><clipPath id="fi224-a"><path d="M60 71.99h50v124.99H60z" fill="none"/></clipPath><clipPath id="fi224-c"><path d="M110 71.99h50v124.99h-50z" fill="none"/></clipPath><symbol id="fi224-b" viewBox="0 0 50 124.98"><path d="m38.39 123.63 5.92-12.36 5.23 13.71a49.87 49.87 0 0 1-11.15-1.35Zm-1.15-.28-4.13-14.23-6.04 10.3a49.2 49.2 0 0 0 10.17 3.93Zm-19.5-81.74 3.14 8.23 4.03-2.79-3.58-7.47Zm7.16 5.45 3.64 7.59 4.29-3.57-3.96-6.76ZM0 64.28v9.49c0 1.51.08 3.01.2 4.49l3.05-2.54-.54-13.32Zm32.3-30.9-4.78-5.67-3.4 1.53 4.43 6.26Zm-20.75 1.51 2.55 8.77 3.64-2.06-3.09-8.11Zm13.62 83.5-2.75-13.49-5.41 7.65a50.51 50.51 0 0 0 8.16 5.84Zm-11.3-8.84-1.31-10.82-3.82 4.52a51.68 51.68 0 0 0 5.13 6.3ZM24.9 37.56l-4.02-6.86-3.14 1.41 3.58 7.47Zm7.93 13.51 4.03 6.86 4.43-4.4-4.23-5.98Zm8.45 2.46 4.29 6.07L50 54.36l-4.36-5.16ZM24.9 37.55l3.96 6.76 3.96-2.74-4.29-6.07ZM41 35.91l4.56 4.54L50 36.77l-4.64-3.86ZM14.28 0h-3.41l13.25 5.96 5.34-.76ZM8.65 0H7.07l10.06 6.96 3.06-.44ZM5.87 0h-.95l7.65 7.61 2.08-.3Zm28.34 0h-13.9l16.94 4.08L50 2.25Zm7.07 44.03 4.36 5.16L50 44.86l-4.43-4.4Zm-8.45-2.46 4.22 5.98 4.23-3.52-4.43-5.24ZM50 23.37l-5.69-3.21-4.91 2.21 5.57 3.85ZM0 0v9.41l.57-.08L.2.01H0Zm0 40.08v11.55l2.22-1.26-.45-11.09ZM50 29.7l-5.03-3.48-4.55 2.57 4.94 4.12Zm-9.58-.91-5.36-4.47-3.93 1.77 5.1 5.07ZM0 19.18v10.16l1.36-.47-.4-9.93ZM1 0H.59L1.7 9.16 2.84 9Zm40.01 35.91-4.78-4.76-3.93 2.23 4.56 5.41ZM4.13 0h-.67l5.72 8.09 1.59-.23ZM1.87 0h-.45l2.57 8.84 1.18-.17Zm1 0h-.52l4.07 8.49 1.32-.19Zm11.67 15.68L9.18 8.09l-1.44.21 4.64 7.9Zm11.28-2.72-8.69-6.01-2.48.36 7.77 6.47ZM50 7.14 37.26 4.07l-7.8 1.12 11.83 4.05Zm-15.13 3.65L24.12 5.96l-3.93.56 9.68 5.47Zm5.55 68.63 4.55 9.49L50 80.33l-4.64-7.9Zm-9.29-2.7 3.93 10.29 5.36-7.59-4.19-8.74ZM10.35 16.69l-3.93-8.2-1.24.18 3.24 8.49ZM22.42 72.3l3.18 10.97 5.53-6.55-3.62-9.49ZM3.99 27.98l-2.63.9.42 10.41 3.39-1.53ZM1.7 9.16l-1.13.16.39 9.63 1.88-.45Zm4.71 38.85-4.19 2.37.48 12.03 5.03-3.48Zm.12-30.4L3.98 8.84 2.83 9l1.85 9.06Zm22.59 77.8 3.98 13.72 6.3-10.73-4.34-11.39Zm-9.64-4.88 2.94 14.37 6.71-9.49-3.53-12.14ZM39.4 98.4l4.91 12.87L50 99.4l-5.03-10.5ZM10.76 83.9l1.8 14.82 6.92-8.2-2.6-12.72Zm-7.52-8.17.6 15.05 6.92-6.88-1.59-13.11Zm16.24-61.24-6.92-6.88-1.8.26 6.12 7.25Zm-4.94 51.82 2.35 11.49 5.53-5.5-2.94-10.1Zm-4.19-20.53 2.03 9.94 4.35-3.01-2.63-9.05Zm-1.3-19.53-2.51.86 1.88 9.19 3.14-1.41Zm15.07 2.99-4.64-6.56-2.75.94 4.15 7.08Zm-6.38 2.87-3.64-7.59-2.55.87 3.09 8.11ZM32.3 62.47l3.93 8.2L41.01 65l-4.15-7.08Zm8.72 2.54 4.35 7.42L50 65.86l-4.43-6.26Zm-16.9-6.68 3.4 8.9 4.78-4.76-3.75-7.83Zm7.02-32.25-5.53-5.5-3.18 1.09 5.1 6.04ZM50 17.6l-6.78-3.05-5.5 1.88 6.59 3.72Zm-10.6 4.76-6.29-4.35-3.98 1.36 5.93 4.94ZM16.73 52.72l2.75 9.48 4.64-3.86-3.24-8.49ZM50 12.22l-8.71-2.98-6.43 1.55 8.36 3.76Zm-27.58 9.45-5.53-6.55-2.35.56 4.94 7Zm-5.69 1.95-4.35-7.42-2.03.49 3.75 7.83Zm20.99-7.19-7.85-4.44-4.05.98 7.29 5.04Zm-8.6 2.94-6.71-5.59-2.93.71 6.12 6.09ZM7.74 58.93l1.44 11.85 5.36-4.47-2.16-10.59Zm.67-22.63-3.24 1.46 1.24 10.25 3.93-2.22Zm3.14-10.91-3.14-8.23-1.88.45 2.51 8.64Zm-6.87-7.34-1.85.44 1.15 9.48 2.55-.87Z" fill="#',
						colors[1].toHexStringNoPrefix(3),
						'"/></symbol></defs><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
						colors[0].toHexStringNoPrefix(3),
						'"/><g clip-path="url(#fi224-a)"><use height="124.98" transform="translate(60 72)" width="50" xlink:href="#fi224-b"/></g><g clip-path="url(#fi224-c)"><use height="124.98" transform="matrix(-1 0 0 1 160 72)" width="50" xlink:href="#fi224-b"/></g>'
					)
				)
			);
	}

	function field_225(uint24[4] memory colors) public pure returns (FieldData memory) {
		return
			FieldData(
				'Hyperbend',
				FieldCategories.OLYMPIC,
				string(
					abi.encodePacked(
						'<symbol id="fi225-c" viewBox="-25 -62.5 50 124.9"><path d="m-19.5-12.3 3 4.4 2.1-4-2.8-4.7-2.3 4.3zm14.2-46.2-.6 3.8 1.6 10 .7 3.1-1.6 6 2.7 7.7 1.4-4.7-2.4-8.9 1.9-8.2L.5-38.5 2.1-45l2.5 11.8-.3 1.2-1.1 3.3-2.8-9.7-1.6 5.9 3 8 1.4-4.2L6-21.6l-1.2 3.3-3-6.2-1.4 3.7-3.1-7-1.6 4.8-2.7-6.8 1.8-5.7-2.5-9.6 1.8-9.5-.4-4.3 1 .4zM-25 32.9l5.7-3.8 7 2.3L-18 36l-7-3.1zm2.2-74.1-2.2-8.5 2.2-12.8h.1l2 12.4-2.1 8.9zm13.3 3.8-2.5-9.9L-9.9-58l2.2 12.8-.5 2.4-1.3 5.4zm-6.7-11.1-2 8.2-2.4-9.8 2-12h.1l2.3 13.6 2-12-.1-.9h.2l-.1.8 2.2 13.3-1.9 7.5-2.3-8.7zm-6.6 7.3 2.5 7.6-2.2 6L-25-34l2.2-7.2zm10.1 56-1.4-.8-3.4-2.5 3.1-3.9 4.7 3.4-3 3.8zm2.5-75.1.6.2-.3 2.2-.3-2.4zm-1.7 64.4-2.5 3.5-3.8-3.5 2.6-3.7-3.6-4.2 2.5-4.2 3.6 4.4-2.5 3.9.9 1 2.8 2.8zM-.8 27.5l-4 4.7-7.5-.7 4.1-4.2-4.1-1-2.5-1 4-4.2-5.1-2.5 3.3-3.6 4.9 2.4-3 3.7 6.2 1.7-3.6 4.5 7.3.2zm-18.5 1.6L-25 26l4.8-3.6 5.4 2.8-4.5 3.9zm-5.7-33 2.8-4.1 3 4.2-2.7 4-3.1-4.1zm7.1-23.5-2.4-6.2 2.1-6.7L-16-33l-1.9 5.6zm16 46.2-5.9-1.6 2.8-3.8-4.8-2.5 2.3-3.4 4.7 2.5-2.2 3.4 5.5 1.7-2.4 3.7zm-15.6-7.3-3.4 3.7 4.9 3.3-4.2 3.9-4.8-3.5 4.1-3.7-4.1-3.5 3.6-3.7-3.6-3.8 3.2-4 3.6 3.9-3.2 3.9 3.9 3.5zM-25-22.2l2.4-5.4 2.5 5.6-2.3 4.9-2.6-5.1zM-22.2-8l-2.8-4.5 2.6-4.7 2.9 4.9-2.7 4.3zM4.9-18.3l3.7 6.1-1 2.5-3.9-5.5 1.2-3.1zM-1.8-2.8l1.4-3.1-3.6-4.2-1.6 3.3 3.8 4L-3.3.3l-.2.3-4.1-3.7 1.9-3.7L-9-11l-2 4 3.4 3.9L-9.5.3l4.3 3.6-2.2 3.6-4.5-3.5L-9.5.2-13-3.5l2-3.6-2.9-4-.5-.9 2.1-4.4 3.4 5.2 1.7-3.7 3.3 4.7 1.6-3.6-3.3-5.2-1.7 4.2-3.2-5.6-1.8 4.1-2.8-5-2.2 4.7-2.8-5.5 2.2-5.3 2.8 6.1 1.9-4.7 1.3 2.9 1.3 2.7 1.9-4.8 3.1 6.2.9-2.6.5-1.5 3.2 6 1.5-3.7 3.1 5.6L2.4-12l4.1 4.9-1.2 2.5-4.2-4.5 1.3-3-3.3-5-1.4 3.3 3.5 4.7-1.4 3.2L4.1-2 2.7.8l-4.5-3.6zm17.3 61.7c-.8 1.2-1.6 2.4-2.5 3.5h-1c1.2-1.1 2.4-2.2 3.5-3.5zM7.8-46l.7-3.6 2 2 .8 8.8-1.6 5.6L7.8-46zM4.4 8.7l1.5-2.8-4.8-2.2-1.7 3 5 2-1.8 3-5.3-1.7 2.1-3.3-4.5-2.9L-3.4.5l4.6 3.1L2.8.7l4.6 2.6-1.5 2.6L12 7.2l1.1-2.1-5.8-1.7L8.5 1 4-1.9l1.3-2.6 4.2 3.4-1 2.1L14 3.3l-.9 1.9s4.3.4 6.5.1l-.7 1.5c-2.2.5-6.8.5-6.8.5l-1.2 2.4-6.5-1zM-6.4 42.6l-.9.9c-2.1 2-4.4 3.9-6.8 5.5-3.7-.1-10.8-2.2-10.8-2.2l8.3-4.3-8.3-2.5 7-3.8 7.7 1.5-6.4 4.9c-.1-.2 6.8.5 10.2 0zm1.6-10.4s6.2-.7 9.1-1.8C2.7 32.5 1 34.6-.8 36.7c5.4-1.5 10.7-4.8 15.4-9.6-2.1 3.3-4.3 6.6-6.7 9.7-4.2 3.1-9.1 5.1-14.3 5.9 1.9-1.9 3.8-3.9 5.6-6-2.8.8-8.4 1-8.4 1l-1.1-.1 5.5-5.4zm21.9-71.7-.9 3.7-.2-5.4 1.1 1.7zm-2.3 8.9 1.4-5.2 1.9 13.3-.9 2.7-2.4-10.8-1.2 4.1-2.2-12.3 1.6-6.3.4.4 1.4 14.1zm2.1 41.2c-2.4 1-7.6 1.8-7.6 1.8l1.5-2.7s4.8-.4 7.2-1.2l-1.1 2.1zM4.5-52.9l3 2.4.3 4.5-1.6 7-1.7-13.9zm16 22.9-1.3 4.2-1-11.8 2.1 4.1.2 3.5.6-2 1.2 3.1.6 9.6-.8 2.5L20.5-30zm.6 32c-1.9-.5-5.6-2.1-5.6-2.1l.7-1.5s3.5 2 5.3 2.7l-.4.9zm-8.8-9.4 4.5 4.3-.6 1.4-4.8-3.8.9-1.9zm10.3 6.2L18-5.8l.5-1.3L22.9-2l.3-.6L25-.5V0l-2.1-2-.3.8zm-3 6.5C21.5 5 25 3.8 25 3.8v-.4s-3.2.6-4.8.6l.5-1.2c-2-.2-5.9-1.4-5.9-1.4l.7-1.6-5-3.3-1 2.1 5.3 2.7-.8 1.9s4.1.8 6.1.8c-.1.4-.3.9-.5 1.3zm1.1-2.4.5-.9c1.2.3 3.8.5 3.8.5v.4s-2.8.1-4.3 0zm-1.8 3.9C21 6.3 25 4.4 25 4.4v.4s-4.5 2.8-7 3.6l.9-1.6zm3-6.5c1 .5 3.1 1.3 3.1 1.3V2s-2.3-.5-3.5-.9l.4-.8zm1.6-3.6L25-1.2v-.7L23.7-4l-.2.7-3.9-6.6.5-1.5-2.9-8.5-.9 2.4-2.7-9.1-1.1 3.4-2.7-10-1.3 4.3 3 8.8 1-3 3 7.8-.8 2.1 3.8 6 .5-1.4 4.1 5.9.4-.6zm-3.9-6.6-.5 1.4-3.5-6.8.8-2.1 3.2 7.5zm-4.1 23.1 1.4-2.6c3-1.3 8.1-5.2 8.1-5.2V6s-5.9 5.4-9.5 7.2zm7-14.4L25 .6V1L22.3-.6l.2-.6zM25 30.6v3.5c-.7 1.2-1.5 2.4-2.2 3.6.8-2.3 1.6-4.7 2.2-7.1zm-9.5 28.3c4-6.2 7.2-13.7 9.5-21.9v7.6c-.4 1.5-.9 3-1.4 4.5-2.5 3.4-5.2 6.7-8.1 9.8zm2.1 3.6c2.4-4.3 4.3-8.7 5.9-13.4.5-.7.9-1.4 1.4-2v5.6c-1.1 3.3-2.3 6.6-3.8 9.8h-3.5zm3.7 0c1.3-1.5 2.5-3.1 3.7-4.7v4l-.3.7h-3.4zm-20.9 0h-11.3c1.1-.7 2.1-1.4 3.1-2.1-5.6 1.6-11.6 1.8-17.2.4 4.6-1.1 9.1-3.1 13.4-5.8-4.5.6-9 .3-13.4-1 3.7-1 7.3-2.7 10.8-4.9 4.5.2 9-.6 13.2-2.4-3.2 3.1-6.8 5.9-10.6 8.3 8.1-.9 15.9-5.1 22.8-12.2C5.7 49.4-.6 55.4-7.7 60.4-5 59.6-2.3 58.5.2 57c10.2-5.6 18.7-17.5 23.9-33.2-1.9 3.4-4 6.7-6.2 9.9C21 28.5 23.4 23 25 17.2v3.5l-.9 3 .9-1.6v3C20.4 42.7 11.2 55.4.4 62.5zM19.8 18C15.3 24.1 10 28.3 4.3 30.4c1.4-1.8 2.7-3.6 4-5.5 5.5-2.5 10.5-7.1 14.8-13.4-1.1 2.2-2.1 4.4-3.3 6.5 2-2.7 3.7-5.6 5.2-8.6v1.4c-2.8 6.5-6.3 12-10.4 16.2 1.8-2.9 3.6-5.9 5.2-9zm-8.5 2.3 2.4-3.9C17.8 14.3 25 6.8 25 6.8v.8c-.1 0-8.6 10.1-13.7 12.7zM-1 46.6c1.6-1.5 3.1-3 4.5-4.6 1.5-1.7 3-3.5 4.4-5.4 7.1-5 13-13.5 17.1-24.2v2.2c-5.5 16.5-15.2 27.5-26 32zM9.6-14.7l-3.5-6.9L7.2-25l3.3 7.7-.9 2.6zm5.1 1.5-.8 1.9-3.4-6.1.9-2.7 3.3 6.9zm-1.6 3.9-.8 1.9-3.8-4.8 1-2.5 3.6 5.4zm4.3 4.9-4.3-4.8.8-2 4 5.5-.5 1.3zM-16-33l2-6.7 2.7 8.1-1.9 5.5L-16-33zm7.3-1.4 1.6 4.6-1.6 4.6-2.6-6.4 1.7-5.8.9 3zM21.9.3C20.1-.7 16.8-3 16.8-3l.6-1.4 4.8 3.9-.3.8zM-.5-55.6l-1.2 5.9-.9-7.5 2.1 1.1v.5zm5.2 22.4L6.2-39l2.3 10-1.3 4-2.5-8.2zm-.8-20.2L2.1-45l-1-8.4-.1-1.9 2.9 1.9zm9.8 69.7C11.1 17.7 5.4 19 5.4 19l.9-1.4 1.3-2.1-7-.3 2-3.3 6.8.6-1.8 3.1s5.4-1.1 7.9-2.3l-1.8 3zm10.2-39.4.1.3-.1.2v-.5zm.4 17.6c-1.2-3-3-9.3-3-9.3l.7-2.1s1.5 7 2.6 10.5c.1 0-.3.9-.3.9zm-.4-17.1s.5 7.7 1.1 11.5v3.7c-1-3.9-2.1-11.9-2.1-11.9l1-3.3zM23.7-4l-3.6-7.4.6-1.6-2.6-9.5 1.1-3.3 2.2 11-.7 1.8L24-4.8l.3-.7c.2.5.7 1.5.7 1.5v1l-1-1.9-.3.9zM-4.6 22.7zm27.4 15c-3.6 10.1-8.7 18.6-14.7 24.8H1.8c7.7-6.5 14.7-14.9 21-24.8zM6.5-7.1l.1-.3.9-2.3 3.9 4.2-.9 2-4-3.6zm1.8 32c-2.9 1.4-9.1 2.6-9.1 2.6l3.5-4.6-7.3-.2.4-.5 2.3-3.3 7.3.1-2.7 3.9s5.9-1.2 8.6-2.6c-1 1.6-2 3.1-3 4.6z" fill="#',
						colors[1].toHexStringNoPrefix(3),
						'"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
						colors[0].toHexStringNoPrefix(3),
						'"/><defs><path d="M110 72h50v125h-50z" id="fi225-a"/></defs><clipPath id="fi225-b"><use overflow="visible" xlink:href="#fi225-a"/></clipPath><g clip-path="url(#fi225-b)"><use height="124.9" overflow="visible" transform="matrix(1 0 0 -1.0004 135 134.485)" width="50" x="-25" xlink:href="#fi225-c" y="-62.5"/></g><defs><path d="M60 72h50v125H60z" id="fi225-d"/></defs><clipPath id="fi225-e"><use overflow="visible" xlink:href="#fi225-d"/></clipPath><g clip-path="url(#fi225-e)"><use height="124.9" overflow="visible" transform="matrix(-1 0 0 -1.0004 85 134.485)" width="50" x="-25" xlink:href="#fi225-c" y="-62.5"/></g>'
					)
				)
			);
	}

	function field_226(uint24[4] memory colors) public pure returns (FieldData memory) {
		return
			FieldData(
				'Burst',
				FieldCategories.OLYMPIC,
				string(
					abi.encodePacked(
						'<symbol id="fi226-a" viewBox="-33.8 -25 67.2 48.7"><path d="m8.1-17.9-11.9-5.8 5-.4 8.1 4.5 5.8 5.1-1.6 1.4zm4.3 14.6-2 .6-1.1-2 2.2-.5zm1.1-2.6 1.9-.9.9 1.9-1.9.9zm-2 .7L10.3-7l2.1-.7 1.1 1.8zm10.1-4 5.5-14.5h2.1l-6 15.9-2.5 2.4-.8-2zm-4.5 6.3.5 2.1-1.9.9-.6-2.1zm1.8-21.4 1.9.6-3.9 10.3-.4.5-1.4-1.6zM18.5-12l4.4-11.7H25l-4.9 13.1-1.2 1.2-1.2-1.8zm3.8 16.8-8.4 18.9-1.8-.7 8.1-18.3L20 .3 21.9-1zm-45.1-17.9-1.5-1.5.1-.1 2.7.3zM5.4 4.1-9 1.3l-3.4-4 1.1.5L5.4 2l2-.1.2 2.1zm.3-18.5-22-7.9-.1-1.4 2.4-.7 20.9 8.2 4.8 4.2-2.2.8zM5.4-.1l-15.8-4-7.9-4.4-3-3.1.9-1L-9.5-6 5.4-2.2h.5l1 2zm8.5 4.6L8 17.7l-1.9-.5 5.7-12.8v-1l2.1-.5zm4.2.2-7.1 16-1.8-.9L16 4.6l-.1-2.4 2.1-.8zm-36.6-28.4.1 2-2.7-2.2z" fill="#',
						colors[1].toHexStringNoPrefix(3),
						'"/><path d="m14.4-4 .7 2-1.9.7-.8-2zm-48.2-19.6 10.4-1.4-6.1 6z" fill="#',
						colors[1].toHexStringNoPrefix(3),
						'"/><path d="m-24.8-23.7 2.1-.6v2.3l-2 1.9zm-1 7.6-1.5-1.5 2.6-2.5.1 2.9zM9.7 4.4 5 14.7l-1.8-.6L7.6 4l2.1-.2zm-30.4-25.3-1.9 1.7-.1-2.8 1.9-1.7h.1l.1-.2.1 3.2zm2.3-.8 2 1.5-2-.2z" fill="#',
						colors[1].toHexStringNoPrefix(3),
						'"/><path d="M-22.5-16.6h.3l-2 1.9h-.3l-.1-2.5 2-2zm3.6 2.5-2.6-.3 1-.9zM7-4.4l1.2 2-2.3.2-1.5-2.2 1 .1zM-8-9.2 2-6.7l2.4 2.3-13-3.5-10.3-6.2 4.9.8zM26.3-5l-4.4 4-.5-2.2 3.4-3.2 6.5-17.3h2.1zm-9.1-3 1.7-1.4 1 2-1.8 1.3zm1.7 4 1.8-1.4.7 2.2-1.9 1.3zM8.8-8.9 7-10.7l2.5-.5 1.6 1.7zm4.4 7.6.4 2.1-2 .5-.5-2zm-.1-9.1L11.7-12l1.8-1.1 1.4 1.6zm1.8-1.1 1.6-1.4 1.2 1.7-1.6 1.4zM9.5 1.7l-2.1.2-.5-2.1L9-.4z" fill="#',
						colors[1].toHexStringNoPrefix(3),
						'"/><path d="m-6.8-11.7 9.6 3 2.5 2.2L2-6.7l-16-6.6-4.1-2.8 4.9.8zm1.6-4.2 8.8 5.2H7l-11.7-6.7-11.7-2.7 4 2.8z" fill="#',
						colors[1].toHexStringNoPrefix(3),
						'"/><path d="m-6.1-13.4 8.9 4.7 3.4.1-2.6-2.1-16-6.6-4.9-.8 4.1 2.8zM11.6 1.3l.2 2.1-2.1.4-.2-2.1zm-32.1-22 3.2 2.6-3.2-.5zm31.6 20L9-.4l-.8-2 2.2-.3zM8-6.6l1.3 1.9-2.3.3-1.7-2.1.1.1zm-26.1-9.5-4.1-.5 1.5-1.5zM19.5-1.9 20 .3l-2 1.1-.4-2.2zm-3.2-3 1.8-1.2.8 2.1-1.8 1.1zm-.6 5 .2 2.1-2 .7-.3-2.1z" fill="#',
						colors[1].toHexStringNoPrefix(3),
						'"/><path d="m8-6.6-1.8-2 2.6-.3L10.3-7zm6.3-2 1.8-1.2L17.2-8l-1.8 1.2zm-1.9.9-1.3-1.8 2-.9 1.2 1.8z" fill="#',
						colors[1].toHexStringNoPrefix(3),
						'"/></symbol><symbol id="fi226-d" viewBox="-66.8 -34.7 133.6 68.1"><use height="48.7" overflow="visible" transform="translate(33.395 -9.727)" width="67.2" x="-33.8" xlink:href="#fi226-a" y="-25"/><use height="48.7" overflow="visible" transform="matrix(-1 0 0 1 -33.395 -9.727)" width="67.2" x="-33.8" xlink:href="#fi226-a" y="-25"/><use height="48.7" overflow="visible" transform="matrix(0 1 1 0 23.668 0)" width="67.2" x="-33.8" xlink:href="#fi226-a" y="-25"/><use height="48.7" overflow="visible" transform="rotate(90 -11.834 -11.834)" width="67.2" x="-33.8" xlink:href="#fi226-a" y="-25"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
						colors[0].toHexStringNoPrefix(3),
						'"/><defs><path d="M60 72v75c0 27.6 22.4 50 50 50s50-22.4 50-50V72H60z" id="fi226-b"/></defs><clipPath id="fi226-c"><use overflow="visible" xlink:href="#fi226-b"/></clipPath><g clip-path="url(#fi226-c)"><use height="68.1" overflow="visible" transform="matrix(1 0 0 -1.2104 110 91.579)" width="133.6" x="-66.8" xlink:href="#fi226-d" y="-34.7"/><use height="68.1" overflow="visible" transform="matrix(1 0 0 1.2104 110 172.421)" width="133.6" x="-66.8" xlink:href="#fi226-d" y="-34.7"/></g>'
					)
				)
			);
	}

	function field_227(uint24[4] memory colors) public pure returns (FieldData memory) {
		return
			FieldData(
				'Shattered',
				FieldCategories.OLYMPIC,
				string(
					abi.encodePacked(
						'<symbol id="fi227-c" viewBox="-25 -30 50 70.1"><path d="M-17.3 4.6-25 6.7l6.7 1.8 1-3.9zm-5.9 22.2L-25 25l3-3-1.2 4.8zM22-22l3-3v4.9l-1.7.5L22-22zm-9.3 9.3-1-3.8-2.5.7L11-19l.7 2.5 6.6-1.8-5.6 5.6L13.9-8 6.3-3.7 5-5l7.7-7.7zM-25-25l5-5 1.7 1.7L-22-22l-3-3zM3.9-14.4l5.3-1.4-5.5 9.5-1.6-1.6 1.8-6.5zm10 6.4L25-14.4v7.7L15-4l-1.1-4zm-.4-15.3L11-19l-1.8-6.8 4.3 2.5zm9.8 3.7 1.7 2.9-4-2.3 2.3-.6zM-18.3 8.5l2.5.7L-19 11l.7-2.5zm5-4.9-4 1.1 1.5-5.5 2.5 4.4zM9.2 15.8 17.3 30H8L3.9 14.4l5.3 1.4zm-16.9-2.5-4.8 8.3-5.8-3.3 7.7-7.7 1.6.4 1.3 2.3 1-1.7 3.4.9-1.5 5.7L2 30l-8.7-5 1.8-6.8-2.8-4.9zM-17.3-30l3.7 6.3-4.6-4.6.9-1.7zM21-19l-2.7.7 1.4-1.4 1.3.7zM7.2-27l.8-3 1.1 4.2L7.2-27zM-19 11l-1.6 6 2.3 1.3L-22 22l1.3-5-4.4-2.5L-19 11zm41-33-2.2 2.2-6.3-3.6 3.8-6.7L22-22zM3.7-6.3 5-5 0 0l3.7-6.3zM19 11s4.6 2.6 4.6 2.7l-5.4-5.4-1-3.7L25 6.7v7.7l-1.3-.8L25 15v5.1l-3.8-1L19 11zm-5.3-7.3 3.7 1L15-4 7.9-2.1 6.4-3.6 0 0l7.9-2.1 5.8 5.8zM7.9-2.1zM18.3 8.3 19 11 0 0l13.7 3.7 4.6 4.6zm-9.2 7.5L0 0l18.3 18.3-9.2-2.5zM22 22l-3.7-3.7 2.9.8.8 2.9zm-34.5-43.7-1.2-2L-12-22l-.5.3zM24.1 30 22 22l3 3v5h-.9zm-38-38-1.9-1.1 2.4-.6-.5 1.7zM-25-14.4l1-.6 1 1.7-2-1.1zm21.7 26.9L0 0l3.9 14.4-7.2-1.9zM-20-8l-3-5.3 7.2 4.2L-20-8l1.8 3.2-6.8-1.9 5-1.3zm9-11-1.7 6.3-5.6-5.6 5.8-3.4L-11-19l.4-1.6 6.9 6.9-3-11.3-3.2 1.8L-8-30l1.3 5L2-30l5.3 3-3.4 12.6-6.5 1.8-1-1 .3 1.2-3.3.9L-11-19zm4.3 7.4L0 0l-10.6-10.6 3.9-1zm-6-1.1 2.1 2.1-2.9.8.8-2.9zm.7-9.3 2.1-1.2-.7 2.6L-12-22zm-13 5.3 3-5.3 3.7 3.7L-24-15l-1-1.7zm22.3 4 4.8 4.8L0 0l-3.3-12.5.6-.2zM-13.9-8 0 0l-15-4 1.1-4zm-4.3 3.1 3.2.9-.8 3.2-2.4-4.1zm4.9 8.5L0 0l-11.5 6.7-1.8-3.1zM-9 11l-.7-1.2-.8.8-5.3-1.4 4.3-2.5 1.8 3.1L0 0l-6.7 11.6L-9 11zm-16 22.3 1.8-6.5 4.9 4.9-4.9 8.4-1.8-6.8zm6.7-1.6 5.8-10 5.8 3.3-3.9 14.4-7.7-7.7z" fill="#',
						colors[1].toHexStringNoPrefix(3),
						'"/></symbol><path d="M60 72v75c0 27.6 22.4 50 50 50s50-22.4 50-50V72H60z" fill="#',
						colors[0].toHexStringNoPrefix(3),
						'" id="fi227-a"/><clipPath id="fi227-b"><use overflow="visible" xlink:href="#fi227-a"/></clipPath><g clip-path="url(#fi227-b)"><use height="70.1" overflow="visible" transform="matrix(1 0 0 -1 135 102)" width="50" x="-25" xlink:href="#fi227-c" y="-30"/><use height="70.1" overflow="visible" transform="rotate(180 42.5 51)" width="50" x="-25" xlink:href="#fi227-c" y="-30"/><use height="70.1" overflow="visible" transform="translate(135 162)" width="50" x="-25" xlink:href="#fi227-c" y="-30"/><use height="70.1" overflow="visible" transform="matrix(-1 0 0 1 85 162)" width="50" x="-25" xlink:href="#fi227-c" y="-30"/></g>'
					)
				)
			);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './ICategories.sol';

interface IFieldSVGs {
	struct FieldData {
		string title;
		ICategories.FieldCategories fieldType;
		string svgString;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICategories {
	enum FieldCategories {
		BASIC,
		EPIC,
		HEROIC,
		OLYMPIC,
		LEGENDARY
	}

	enum HardwareCategories {
		BASIC,
		EPIC,
		DOUBLE,
		MULTI
	}

	enum FrameCategories {
		NONE,
		ADORNED,
		MENACING,
		SECURED,
		FLORIATED,
		EVERLASTING
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library HexStrings {
	bytes16 internal constant ALPHABET = '0123456789abcdef';

	function toHexStringNoPrefix(uint256 value, uint256 length)
		internal
		pure
		returns (string memory)
	{
		bytes memory buffer = new bytes(2 * length);
		for (uint256 i = buffer.length; i > 0; i--) {
			buffer[i - 1] = ALPHABET[value & 0xf];
			value >>= 4;
		}
		return string(buffer);
	}
}