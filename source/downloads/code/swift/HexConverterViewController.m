//
//  ViewController.swift
//  HexConverter_swift
//
//  Created by taowang on 7/24/14.
//  Copyright (c) 2014 Meilishuo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var beforeConvertTextField: UITextField
    @IBOutlet var afterConvertTextField: UITextField
    @IBOutlet var segmentControl: UISegmentedControl
                            
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.segmentControl.addTarget(self, action: Selector("setTextFieldKeyboardType"), forControlEvents: UIControlEvents.ValueChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func decimalConvertedFromHexdecimal(hexdecimal: NSString) -> NSString? {
    
        var sum: Int = 0
        for (var i: Int = 0; i < hexdecimal.length; i++) {
            var c: unichar = hexdecimal.characterAtIndex(i)
            
            var num: unichar = 0;
            if (c >= 65 && c <= 70) {
                num = c - 55;
            } else if (c >= 97 && c <= 102) {
                num = c - 87;
            } else if (c >= 48 && c <= 57) {
                num = c - 48;
            } else {
                let alert = UIAlertController(title: "错误", message: "你提供了非法字符", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "知道了", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)

                self.beforeConvertTextField.text = ""
                self.beforeConvertTextField.becomeFirstResponder()
                
                return nil
            }
            
            let tmp = Int(pow(16, CDouble(hexdecimal.length - i - 1)))
            
            sum = sum + Int(num) * tmp
        }
        
        return NSString(format: "%d", sum)
    }
    
    func hexdecimalConvertedFromDecimal(decimal: NSString) -> NSString? {
        
        var num: Int = decimal.integerValue;
        var result: NSMutableString = NSMutableString(capacity: 0);
            
        while (num > 0) {
            var tmp = num % 16;
            var c: unichar = 48;
            if (tmp > 9) {
            c = 97 + unichar(tmp - 10);
            } else {
                c = 48 + unichar(tmp);
            }
            let character: NSString = NSString(format:"%c", c)
            result.insertString(character, atIndex: 0)
            num /= 16;
        }

        return result;
    }
    
    func setTextFieldKeyboardType() {
        self.beforeConvertTextField.resignFirstResponder()
        if (self.segmentControl.selectedSegmentIndex == 0) {
            self.beforeConvertTextField.keyboardType = .ASCIICapable;
        } else {
            self.beforeConvertTextField.keyboardType = .NumberPad;
        }
        self.beforeConvertTextField.becomeFirstResponder();
    }

    @IBAction func endEditing(sender: AnyObject) {
        self.view.endEditing(true)
    }

    @IBAction func convertButtonPressed(sender: AnyObject) {
        if ("" == self.beforeConvertTextField.text)  {
            var alert = UIAlertController(title: "提示", message: "你还没有填写被转换数字", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        self.beforeConvertTextField.resignFirstResponder()
        if (0 == self.segmentControl.selectedSegmentIndex) {
            self.afterConvertTextField.text = self.decimalConvertedFromHexdecimal(self.beforeConvertTextField.text)
        } else {
            self.afterConvertTextField.text = self.hexdecimalConvertedFromDecimal(self.beforeConvertTextField.text)
        }
    }
    
}

